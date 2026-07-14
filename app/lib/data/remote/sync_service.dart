import 'package:supabase_flutter/supabase_flutter.dart';

import '../progress_repository.dart';
import 'api_client.dart' show ApiException, TeacherClass, ClassRoster, StudentDetail, Leaderboard;
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

/// Supabase-backed sync + teacher dashboard client (Option B, `supabase-native`
/// branch). Replaces the HTTP calls to the Node server with Supabase Auth +
/// RPC. Offline-first is preserved: the local Drift DB holds all progress, and
/// every sync sends cumulative aggregates that the `sync_progress` function
/// replaces idempotently, so a failed sync loses nothing.
///
/// Auth: students use anonymous sign-in (free, no OTP); teachers use email +
/// password. One session per device; a device is a student's or a teacher's.
class SyncService {
  final ProgressRepository progress;
  final SyncStateStore store;

  const SyncService({required this.progress, required this.store});

  // Accessed lazily so tests that never sync don't require Supabase.initialize.
  SupabaseClient get _sb => Supabase.instance.client;

  Future<bool> isLoggedIn() async {
    final u = _sb.auth.currentUser;
    return u != null && u.isAnonymous;
  }

  Future<DateTime?> lastSyncAt() => store.lastSyncAt();

  /// Student login: anonymous sign-in, set profile, optionally join a class.
  /// Throws [ApiException] (e.g. bad enrolment code) so the UI can show it.
  Future<void> login({
    required String phone,
    String? name,
    String? schoolCode, // unused on Supabase; class code replaces it
    String? enrollCode,
  }) async {
    try {
      final u = _sb.auth.currentUser;
      if (u == null) {
        await _sb.auth.signInAnonymously();
      } else if (!u.isAnonymous) {
        await _sb.auth.signOut();
        await _sb.auth.signInAnonymously();
      }
      await _sb.rpc('upsert_student', params: {
        'p_name': name ?? '',
        'p_phone': phone,
      });
      if (enrollCode != null && enrollCode.trim().isNotEmpty) {
        await _sb.rpc('join_class', params: {'p_code': enrollCode.trim()});
      }
    } on PostgrestException catch (e) {
      throw ApiException(e.message);
    } on AuthException catch (e) {
      throw ApiException(e.message);
    }
  }

  Future<void> logout() async {
    await _sb.auth.signOut();
    await store.clear();
  }

  // ── Teacher session ────────────────────────────────────────────────────────

  Future<bool> isTeacherLoggedIn() async {
    final u = _sb.auth.currentUser;
    return u != null && !u.isAnonymous;
  }

  /// Teacher login by email + password (signs up on first use). Throws
  /// [ApiException] on bad credentials / unconfirmed email.
  Future<void> teacherLogin({
    required String email,
    required String password,
  }) async {
    try {
      // Never carry an existing (e.g. anonymous student) session into a teacher
      // login — signing up while anonymous would link the student's identity to
      // the teacher email. Start from a clean session.
      if (_sb.auth.currentUser != null) {
        await _sb.auth.signOut();
      }
      try {
        await _sb.auth.signInWithPassword(email: email.trim(), password: password);
      } on AuthException {
        // No such account yet → create one (email confirmation is disabled for
        // the pilot, so this yields a session immediately).
        await _sb.auth.signUp(email: email.trim(), password: password);
      }
      if (_sb.auth.currentUser == null) {
        throw const ApiException('could not sign in');
      }
      await _sb.rpc('ensure_teacher', params: {'p_name': '', 'p_phone': ''});
    } on AuthException catch (e) {
      throw ApiException(e.message);
    } on PostgrestException catch (e) {
      throw ApiException(e.message);
    }
  }

  Future<void> teacherLogout() => _sb.auth.signOut();

  Future<List<TeacherClass>> teacherClasses() async {
    final res = await _sb.rpc('my_teacher_classes');
    return (res as List<dynamic>)
        .map((e) => TeacherClass.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ClassRoster> classRoster(String classId) async {
    final res = await _sb.rpc('teacher_class_roster', params: {'p_class_id': classId});
    return ClassRoster.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<StudentDetail> studentDetail(String studentId) async {
    final res =
        await _sb.rpc('teacher_student_detail', params: {'p_student_id': studentId});
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
