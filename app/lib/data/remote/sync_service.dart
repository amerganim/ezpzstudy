import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../progress_repository.dart';
import 'api_client.dart' show ApiException, RosterStudent, StudentDetail, Leaderboard;
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

/// Supabase-backed sync client (Option B, `supabase-native` branch), kept
/// deliberately simple for the pilot:
///   • Practice needs no account at all.
///   • "Save my progress" signs the device in anonymously (free, no OTP) and
///     stores the student's name + phone, then pushes cumulative aggregates.
///   • Anyone (teacher/parent) can view every student's progress with NO login,
///     via the public_roster / public_student_detail RPCs.
///
/// Offline-first is preserved: the local Drift DB holds all progress, and every
/// sync sends cumulative aggregates that `sync_progress` replaces idempotently,
/// so a failed sync loses nothing.
class SyncService {
  final ProgressRepository progress;
  final SyncStateStore store;

  SyncService({required this.progress, required this.store});

  // Accessed lazily so tests that never sync don't require Supabase.initialize.
  SupabaseClient get _sb => Supabase.instance.client;

  // Coalesces concurrent init attempts; nulled on failure so a later call retries.
  Future<void>? _initFuture;

  /// True once `Supabase.initialize` has run (survives hot restart).
  bool get _isInitialized {
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Ensures Supabase is initialized before any network call. Initialization is
  /// deferred (not done at app start) so a slow/unreachable network can never
  /// delay or crash the offline-first UI. Safe to call repeatedly; retries after
  /// a failed attempt.
  Future<void> ensureReady() async {
    if (_isInitialized) return;
    final pending = _initFuture ??= Supabase.initialize(
      url: SupabaseConfig.url,
      // JWT anon key (publishable); anonKey is the right param for this format.
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
    ).then((_) {});
    try {
      await pending;
    } catch (e) {
      _initFuture = null; // let the next attempt try again
      throw ApiException('backend unavailable: $e');
    }
  }

  /// Fire-and-forget warm-up used at app start: begins initialization early but
  /// never throws, so the UI is never blocked or broken by a slow network.
  Future<void> warmUp() async {
    try {
      await ensureReady();
    } catch (_) {
      // Ignored — features that need the backend will retry on demand.
    }
  }

  /// Whether a student is signed in. Never throws and never depends on the
  /// network having initialized yet — if the backend isn't ready, the answer is
  /// simply "not logged in", so the home screen always renders instantly.
  Future<bool> isLoggedIn() async {
    if (!_isInitialized) return false;
    try {
      final u = _sb.auth.currentUser;
      return u != null && u.isAnonymous;
    } catch (_) {
      return false;
    }
  }

  Future<DateTime?> lastSyncAt() => store.lastSyncAt();

  /// "Save my progress": anonymous sign-in + store the student's name & phone.
  /// Throws [ApiException] on failure so the UI can show a friendly retry.
  Future<void> login({
    required String phone,
    required String name,
  }) async {
    await ensureReady();
    try {
      final u = _sb.auth.currentUser;
      if (u == null || !u.isAnonymous) {
        if (u != null) await _sb.auth.signOut();
        await _sb.auth.signInAnonymously();
      }
      await _sb.rpc('upsert_student', params: {
        'p_name': name,
        'p_phone': phone,
      });
    } on PostgrestException catch (e) {
      throw ApiException(e.message);
    } on AuthException catch (e) {
      throw ApiException(e.message);
    }
  }

  Future<void> logout() async {
    if (_isInitialized) {
      try {
        await _sb.auth.signOut();
      } catch (_) {/* ignore — clearing local state below is what matters */}
    }
    await store.clear();
  }

  // ── Public progress views (no login required) ───────────────────────────────

  /// Every student's rollup, ranked — for the "see all students" screen that
  /// any teacher/parent can open without an account.
  Future<List<RosterStudent>> allStudents() async {
    await ensureReady();
    try {
      final res = await _sb.rpc('public_roster');
      final map = Map<String, dynamic>.from(res as Map);
      return (map['students'] as List<dynamic>? ?? const [])
          .map((e) => RosterStudent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw ApiException(e.message);
    }
  }

  /// One student's per-topic breakdown (public, no login).
  Future<StudentDetail> studentDetail(String studentId) async {
    await ensureReady();
    final res =
        await _sb.rpc('public_student_detail', params: {'p_student_id': studentId});
    return StudentDetail.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// This week's class leaderboard, or null if not logged in / unreachable.
  Future<Leaderboard?> fetchLeaderboard() async {
    if (!await isLoggedIn()) return null;
    try {
      final res = await _sb.rpc('my_leaderboard');
      final lb = Leaderboard.fromJson(Map<String, dynamic>.from(res as Map));
      if (lb.myRank == null) {
        for (final e in lb.entries) {
          if (e.isMe) {
            return Leaderboard(
              scoped: lb.scoped,
              week: lb.week,
              entries: lb.entries,
              myRank: e.rank,
              myPoints: e.points,
            );
          }
        }
      }
      return lb;
    } catch (_) {
      return null;
    }
  }

  /// Pushes the current cumulative aggregates. Safe anytime; returns an outcome
  /// rather than throwing.
  Future<SyncOutcome> syncNow() async {
    if (!await isLoggedIn()) {
      return const SyncOutcome(SyncStatus.notLoggedIn);
    }
    final snapshot = await progress.snapshot();
    final topics = [
      for (final t in snapshot.topics)
        {
          'topic': t.topic,
          'attempts': t.attempts,
          'correct': t.correct,
          if (t.lastPracticed != null)
            'last_practiced': t.lastPracticed!.toUtc().toIso8601String(),
        },
    ];
    try {
      await _sb.rpc('sync_progress', params: {
        'p_topics': topics,
        'p_streak': snapshot.streakDays,
        'p_sessions': snapshot.totalSessions,
      });
      await store.markSynced(DateTime.now());
      return const SyncOutcome(SyncStatus.success);
    } on PostgrestException catch (e) {
      return SyncOutcome(SyncStatus.error, message: e.message);
    } catch (e) {
      // Transport failure (offline, DNS, timeout) — practice is unaffected.
      return SyncOutcome(SyncStatus.offline, message: e.toString());
    }
  }

  /// Fire-and-forget sync on app resume: only if logged in and it has been at
  /// least [minInterval] since the last success. Never throws.
  Future<SyncOutcome> maybeSync(
      {Duration minInterval = const Duration(hours: 6)}) async {
    if (!await isLoggedIn()) {
      return const SyncOutcome(SyncStatus.notLoggedIn);
    }
    final last = await store.lastSyncAt();
    if (last != null && DateTime.now().difference(last) < minInterval) {
      return const SyncOutcome(SyncStatus.success);
    }
    return syncNow();
  }
}
