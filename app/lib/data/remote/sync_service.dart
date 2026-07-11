import '../progress_repository.dart';
import 'api_client.dart';
import 'sync_state_store.dart';

/// The result of a sync attempt. Everything except [success] is non-fatal:
/// practice continues regardless, and the local DB still holds all progress.
enum SyncStatus { success, offline, notLoggedIn, error }

class SyncOutcome {
  final SyncStatus status;
  final String? message;
  const SyncOutcome(this.status, {this.message});

  bool get isSuccess => status == SyncStatus.success;
}

/// Syncs aggregated progress to the backend. Deliberately queue-free: because
/// /sync sends cumulative aggregates and the server replaces them idempotently,
/// the local DB *is* the durable queue. A failed (offline) sync loses nothing —
/// the next attempt sends the current cumulative state. Sync never blocks
/// practice; all errors are swallowed into a [SyncOutcome].
class SyncService {
  final ApiClient api;
  final ProgressRepository progress;
  final SyncStateStore store;

  const SyncService({
    required this.api,
    required this.progress,
    required this.store,
  });

  Future<bool> isLoggedIn() async {
    final token = await store.token();
    return token != null && token.isNotEmpty;
  }

  Future<DateTime?> lastSyncAt() => store.lastSyncAt();

  /// Logs in by phone (find-or-create on the server) and stores the session.
  /// Throws [ApiException] so the login UI can show a real error; sync itself
  /// never throws.
  Future<void> login({
    required String phone,
    String? name,
    String? schoolCode,
  }) async {
    final result = await api.authenticate(
      phone: phone,
      name: name,
      schoolCode: schoolCode,
    );
    await store.saveSession(result.token, result.studentId);
  }

  Future<void> logout() => store.clear();

  /// Fetches this week's class leaderboard. Returns null if not logged in or the
  /// server is unreachable — the UI shows a friendly state rather than an error.
  Future<Leaderboard?> fetchLeaderboard() async {
    final token = await store.token();
    if (token == null || token.isEmpty) return null;
    try {
      return await api.leaderboard(token: token);
    } on ApiException {
      return null;
    }
  }

  /// Pushes the current aggregates to the server. Safe to call anytime; returns
  /// an outcome rather than throwing.
  Future<SyncOutcome> syncNow() async {
    final token = await store.token();
    if (token == null || token.isEmpty) {
      return const SyncOutcome(SyncStatus.notLoggedIn);
    }

    final snapshot = await progress.snapshot();
    final payload = SyncPayload(
      since: await store.lastSyncAt(),
      streakDays: snapshot.streakDays,
      sessions: snapshot.totalSessions,
      topics: [
        for (final t in snapshot.topics)
          SyncTopic(
            topic: t.topic,
            attempts: t.attempts,
            correct: t.correct,
            lastPracticed: t.lastPracticed,
          ),
      ],
    );

    try {
      await api.sync(token: token, payload: payload);
      await store.markSynced(DateTime.now());
      return const SyncOutcome(SyncStatus.success);
    } on ApiException catch (e) {
      if (e.isNetwork) {
        return SyncOutcome(SyncStatus.offline, message: e.message);
      }
      // An expired/invalid token: drop the session so the student can re-login.
      if (e.statusCode == 401) {
        await store.clear();
      }
      return SyncOutcome(SyncStatus.error, message: e.message);
    }
  }

  /// Fire-and-forget sync used on app resume: only attempts if logged in and it
  /// has been at least [minInterval] since the last successful sync. Never
  /// throws; returns the outcome for callers that care.
  Future<SyncOutcome> maybeSync(
      {Duration minInterval = const Duration(hours: 6)}) async {
    if (!await isLoggedIn()) {
      return const SyncOutcome(SyncStatus.notLoggedIn);
    }
    final last = await store.lastSyncAt();
    if (last != null && DateTime.now().difference(last) < minInterval) {
      return const SyncOutcome(SyncStatus.success); // recently synced
    }
    return syncNow();
  }
}
