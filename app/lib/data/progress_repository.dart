import 'db/database.dart';

/// A snapshot of the student's overall progress, used by the home screen.
class ProgressSnapshot {
  final int streakDays;
  final int totalSessions;
  final List<TopicProgressData> topics;

  const ProgressSnapshot({
    required this.streakDays,
    required this.totalSessions,
    required this.topics,
  });

  int get totalAttempts =>
      topics.fold(0, (sum, t) => sum + t.attempts);
  int get totalCorrect => topics.fold(0, (sum, t) => sum + t.correct);
}

/// Owns progress aggregates, the daily streak, and session counting. Stores
/// aggregates only (never per-attempt rows), which is also the exact shape the
/// future /sync endpoint will send.
class ProgressRepository {
  final AppDatabase db;
  const ProgressRepository(this.db);

  static const _streakDaysKey = 'streak_days';
  static const _lastPracticeDayKey = 'last_practice_day';
  static const _totalSessionsKey = 'total_sessions';

  Future<void> recordAttempt(String topic, bool correct, {DateTime? when}) {
    return db.recordAttempt(
      topic: topic,
      correct: correct,
      when: when ?? DateTime.now(),
    );
  }

  /// Call once when a practice session begins. Advances the streak if this is
  /// a new day, resets it if a day was skipped, and increments the session count.
  Future<int> startSession({DateTime? now}) async {
    final today = _dayOnly(now ?? DateTime.now());
    final lastStr = await db.getMeta(_lastPracticeDayKey);
    final currentStreak = int.tryParse(await db.getMeta(_streakDaysKey) ?? '') ?? 0;

    int newStreak;
    if (lastStr == null) {
      newStreak = 1;
    } else {
      final last = DateTime.parse(lastStr);
      final gap = today.difference(last).inDays;
      if (gap == 0) {
        newStreak = currentStreak == 0 ? 1 : currentStreak; // same day
      } else if (gap == 1) {
        newStreak = currentStreak + 1; // consecutive day
      } else {
        newStreak = 1; // streak broken
      }
    }

    await db.setMeta(_streakDaysKey, newStreak.toString());
    await db.setMeta(_lastPracticeDayKey, today.toIso8601String());

    final sessions =
        (int.tryParse(await db.getMeta(_totalSessionsKey) ?? '') ?? 0) + 1;
    await db.setMeta(_totalSessionsKey, sessions.toString());

    return newStreak;
  }

  Future<ProgressSnapshot> snapshot() async {
    final streak = int.tryParse(await db.getMeta(_streakDaysKey) ?? '') ?? 0;
    final sessions =
        int.tryParse(await db.getMeta(_totalSessionsKey) ?? '') ?? 0;
    final topics = await db.allProgress();
    return ProgressSnapshot(
      streakDays: streak,
      totalSessions: sessions,
      topics: topics,
    );
  }

  DateTime _dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
