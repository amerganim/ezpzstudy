import '../db/database.dart';

/// Persists sync/session state (token, student id, last sync time) in the local
/// Meta key-value table. Plain-text token storage is acceptable for the pilot;
/// hardening to secure storage is noted for later.
class SyncStateStore {
  final AppDatabase db;
  const SyncStateStore(this.db);

  static const _tokenKey = 'sync_token';
  static const _studentIdKey = 'sync_student_id';
  static const _lastAtKey = 'sync_last_at';
  static const _teacherTokenKey = 'teacher_token';

  Future<String?> token() => db.getMeta(_tokenKey);
  Future<String?> studentId() => db.getMeta(_studentIdKey);

  // Teacher session (separate from the student session; a teacher's phone).
  Future<String?> teacherToken() => db.getMeta(_teacherTokenKey);
  Future<void> saveTeacherToken(String token) =>
      db.setMeta(_teacherTokenKey, token);
  Future<void> clearTeacher() => db.setMeta(_teacherTokenKey, '');

  Future<DateTime?> lastSyncAt() async {
    final v = await db.getMeta(_lastAtKey);
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<void> saveSession(String token, String studentId) async {
    await db.setMeta(_tokenKey, token);
    await db.setMeta(_studentIdKey, studentId);
  }

  Future<void> markSynced(DateTime when) =>
      db.setMeta(_lastAtKey, when.toUtc().toIso8601String());

  Future<void> clear() async {
    await db.setMeta(_tokenKey, '');
    await db.setMeta(_studentIdKey, '');
  }
}
