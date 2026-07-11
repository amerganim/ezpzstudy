import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezpzstudy/data/db/database.dart';
import 'package:ezpzstudy/data/progress_repository.dart';
import 'package:ezpzstudy/data/remote/api_client.dart';
import 'package:ezpzstudy/data/remote/sync_service.dart';
import 'package:ezpzstudy/data/remote/sync_state_store.dart';

/// Fake backend serving /auth and /leaderboard.
class FakeBackend {
  late HttpServer _server;
  String authHeader = '';
  Map<String, dynamic> board = const {};

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) async {
      await utf8.decoder.bind(req).join();
      if (req.uri.path == '/auth') {
        req.response
          ..statusCode = 200
          ..write(json.encode({
            'token': 'tok',
            'student': {'id': 's1'}
          }));
      } else if (req.uri.path == '/leaderboard') {
        authHeader = req.headers.value('authorization') ?? '';
        req.response
          ..statusCode = 200
          ..write(json.encode(board));
      } else {
        req.response.statusCode = 404;
      }
      await req.response.close();
    });
  }

  Future<void> stop() => _server.close(force: true);
}

void main() {
  late AppDatabase db;
  late SyncService service;
  late FakeBackend backend;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    backend = FakeBackend();
    await backend.start();
    service = SyncService(
      api: ApiClient(baseUrl: backend.baseUrl, timeout: const Duration(seconds: 2)),
      progress: ProgressRepository(db),
      store: SyncStateStore(db),
    );
  });

  tearDown(() async {
    await backend.stop();
    await db.close();
  });

  test('fetchLeaderboard returns null when not logged in', () async {
    expect(await service.fetchLeaderboard(), isNull);
  });

  test('fetchLeaderboard parses a scoped board with the caller flagged',
      () async {
    backend.board = {
      'scoped': true,
      'week': '2026-W28',
      'entries': [
        {'rank': 1, 'name': 'Rahim', 'points': 8, 'is_me': true},
        {'rank': 2, 'name': null, 'points': 5, 'is_me': false},
      ],
      'me': {'rank': 1, 'points': 8},
    };
    await service.login(phone: '01700000000');
    final board = await service.fetchLeaderboard();

    expect(board, isNotNull);
    expect(backend.authHeader, 'Bearer tok');
    expect(board!.scoped, isTrue);
    expect(board.week, '2026-W28');
    expect(board.entries, hasLength(2));
    expect(board.entries.first.isMe, isTrue);
    expect(board.entries[1].name, isNull); // anonymous classmate
    expect(board.myRank, 1);
    expect(board.myPoints, 8);
  });

  test('unscoped board (no school code) parses cleanly', () async {
    backend.board = {
      'scoped': false,
      'week': '2026-W28',
      'entries': [],
      'me': null,
    };
    await service.login(phone: '01700000000');
    final board = await service.fetchLeaderboard();
    expect(board!.scoped, isFalse);
    expect(board.entries, isEmpty);
    expect(board.myRank, isNull);
  });
}
