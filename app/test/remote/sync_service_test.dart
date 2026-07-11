import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezpzstudy/data/db/database.dart';
import 'package:ezpzstudy/data/progress_repository.dart';
import 'package:ezpzstudy/data/remote/api_client.dart';
import 'package:ezpzstudy/data/remote/sync_service.dart';
import 'package:ezpzstudy/data/remote/sync_state_store.dart';

/// A minimal in-process stand-in for the backend, recording what it receives so
/// tests can assert the client sent the right thing.
class FakeBackend {
  late HttpServer _server;
  final List<Map<String, dynamic>> syncBodies = [];
  final List<String> authHeaders = [];
  bool rejectAuth = false; // return 401 from /sync

  int get port => _server.port;
  String get baseUrl => 'http://127.0.0.1:$port';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) async {
      final body = await utf8.decoder.bind(req).join();
      if (req.uri.path == '/auth' && req.method == 'POST') {
        req.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(json.encode({
            'token': 'test-token-abc',
            'student': {'id': 'student-1', 'phone': '01700000000'},
          }));
        await req.response.close();
      } else if (req.uri.path == '/sync' && req.method == 'POST') {
        authHeaders.add(req.headers.value('authorization') ?? '');
        if (rejectAuth) {
          req.response.statusCode = 401;
          await req.response.close();
          return;
        }
        syncBodies.add(json.decode(body) as Map<String, dynamic>);
        req.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(json.encode({'ok': true, 'synced_topics': 1}));
        await req.response.close();
      } else {
        req.response.statusCode = 404;
        await req.response.close();
      }
    });
  }

  Future<void> stop() => _server.close(force: true);
}

void main() {
  late AppDatabase db;
  late ProgressRepository progress;
  late SyncStateStore store;
  late FakeBackend backend;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    progress = ProgressRepository(db);
    store = SyncStateStore(db);
    backend = FakeBackend();
    await backend.start();
  });

  tearDown(() async {
    await backend.stop();
    await db.close();
  });

  SyncService serviceFor(String baseUrl) => SyncService(
        api: ApiClient(
          baseUrl: baseUrl,
          timeout: const Duration(seconds: 2),
        ),
        progress: progress,
        store: store,
      );

  test('login stores the token and student id', () async {
    final service = serviceFor(backend.baseUrl);
    expect(await service.isLoggedIn(), isFalse);
    await service.login(phone: '01700000000', name: 'Rahim');
    expect(await service.isLoggedIn(), isTrue);
    expect(await store.token(), 'test-token-abc');
    expect(await store.studentId(), 'student-1');
  });

  test('syncNow without login reports notLoggedIn and sends nothing', () async {
    final service = serviceFor(backend.baseUrl);
    final outcome = await service.syncNow();
    expect(outcome.status, SyncStatus.notLoggedIn);
    expect(backend.syncBodies, isEmpty);
  });

  test('syncNow posts aggregated progress with the bearer token', () async {
    await progress.recordAttempt('tense', true);
    await progress.recordAttempt('tense', false);
    await progress.recordAttempt('narration', true);
    await progress.startSession();

    final service = serviceFor(backend.baseUrl);
    await service.login(phone: '01700000000');
    final outcome = await service.syncNow();

    expect(outcome.status, SyncStatus.success);
    expect(backend.authHeaders.last, 'Bearer test-token-abc');
    expect(backend.syncBodies, hasLength(1));

    final sent = backend.syncBodies.single;
    final topics = (sent['topic_progress'] as List)
        .cast<Map<String, dynamic>>();
    final byTopic = {for (final t in topics) t['topic'] as String: t};
    expect(byTopic['tense']!['attempts'], 2);
    expect(byTopic['tense']!['correct'], 1);
    expect(byTopic['narration']!['attempts'], 1);
    expect(sent['sessions'], 1);

    // A successful sync records the time.
    expect(await store.lastSyncAt(), isNotNull);
  });

  test('offline sync is non-fatal and loses nothing', () async {
    await progress.recordAttempt('tense', true);
    // Log in against the real backend, then point sync at a dead port.
    final loginService = serviceFor(backend.baseUrl);
    await loginService.login(phone: '01700000000');

    final offlineService = serviceFor('http://127.0.0.1:1'); // nothing listening
    final outcome = await offlineService.syncNow();

    expect(outcome.status, SyncStatus.offline);
    // Progress is untouched and still fully present locally.
    final snap = await progress.snapshot();
    expect(snap.totalAttempts, 1);
    expect(await store.lastSyncAt(), isNull);
  });

  test('a 401 from sync clears the session so the student can re-login',
      () async {
    final service = serviceFor(backend.baseUrl);
    await service.login(phone: '01700000000');
    backend.rejectAuth = true;
    final outcome = await service.syncNow();
    expect(outcome.status, SyncStatus.error);
    expect(await service.isLoggedIn(), isFalse);
  });

  test('maybeSync skips when recently synced', () async {
    await progress.recordAttempt('tense', true);
    final service = serviceFor(backend.baseUrl);
    await service.login(phone: '01700000000');

    final first = await service.maybeSync(minInterval: const Duration(hours: 6));
    expect(first.status, SyncStatus.success);
    expect(backend.syncBodies, hasLength(1));

    // Immediately calling again should skip the network entirely.
    final second = await service.maybeSync(minInterval: const Duration(hours: 6));
    expect(second.status, SyncStatus.success);
    expect(backend.syncBodies, hasLength(1)); // no second POST
  });
}
