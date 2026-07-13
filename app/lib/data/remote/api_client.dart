import 'dart:convert';

import 'package:http/http.dart' as http;

/// Raised for any non-success response or transport failure. Callers treat this
/// as "try again later" — it must never surface to a practising student.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  /// A transport-level failure (offline, DNS, timeout) rather than an HTTP error.
  bool get isNetwork => statusCode == null;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class AuthResult {
  final String token;
  final String studentId;
  const AuthResult({required this.token, required this.studentId});
}

/// One topic's aggregate, as sent to /sync.
class SyncTopic {
  final String topic;
  final int attempts;
  final int correct;
  final DateTime? lastPracticed;
  const SyncTopic({
    required this.topic,
    required this.attempts,
    required this.correct,
    this.lastPracticed,
  });

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'attempts': attempts,
        'correct': correct,
        if (lastPracticed != null)
          'last_practiced': lastPracticed!.toUtc().toIso8601String(),
      };
}

class SyncPayload {
  final DateTime? since;
  final List<SyncTopic> topics;
  final int streakDays;
  final int sessions;
  const SyncPayload({
    this.since,
    required this.topics,
    required this.streakDays,
    required this.sessions,
  });

  Map<String, dynamic> toJson() => {
        if (since != null) 'since': since!.toUtc().toIso8601String(),
        'topic_progress': topics.map((t) => t.toJson()).toList(),
        'streak_days': streakDays,
        'sessions': sessions,
      };
}

class LeaderboardEntry {
  final int rank;
  final String? name;
  final int points;
  final bool isMe;
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.points,
    required this.isMe,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: (j['rank'] as num).toInt(),
        name: j['name'] as String?,
        points: (j['points'] as num).toInt(),
        isMe: j['is_me'] as bool? ?? false,
      );
}

class Leaderboard {
  /// False when the student has no school code yet (nothing to rank against).
  final bool scoped;
  final String week;
  final List<LeaderboardEntry> entries;
  final int? myRank;
  final int myPoints;

  const Leaderboard({
    required this.scoped,
    required this.week,
    required this.entries,
    required this.myRank,
    required this.myPoints,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> j) {
    final me = j['me'] as Map<String, dynamic>?;
    return Leaderboard(
      scoped: j['scoped'] as bool? ?? false,
      week: j['week'] as String? ?? '',
      entries: (j['entries'] as List<dynamic>? ?? const [])
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      myRank: (me?['rank'] as num?)?.toInt(),
      myPoints: (me?['points'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A class a teacher owns, with its enrolment code and live student count.
class TeacherClass {
  final String id;
  final String name;
  final String enrollCode;
  final String? collegeName;
  final int studentCount;
  const TeacherClass({
    required this.id,
    required this.name,
    required this.enrollCode,
    required this.collegeName,
    required this.studentCount,
  });

  factory TeacherClass.fromJson(Map<String, dynamic> j) => TeacherClass(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        enrollCode: j['enroll_code'] as String? ?? '',
        collegeName: j['college_name'] as String?,
        studentCount: (j['student_count'] as num?)?.toInt() ?? 0,
      );
}

/// One student's rollup within a class roster.
class RosterStudent {
  final String id;
  final String? name;
  final int attempts;
  final int correct;
  final int? accuracy;
  final int weeklyPoints;
  final DateTime? lastSyncAt;
  const RosterStudent({
    required this.id,
    required this.name,
    required this.attempts,
    required this.correct,
    required this.accuracy,
    required this.weeklyPoints,
    required this.lastSyncAt,
  });

  factory RosterStudent.fromJson(Map<String, dynamic> j) => RosterStudent(
        id: j['id'] as String,
        name: j['name'] as String?,
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
        correct: (j['correct'] as num?)?.toInt() ?? 0,
        accuracy: (j['accuracy'] as num?)?.toInt(),
        weeklyPoints: (j['weekly_points'] as num?)?.toInt() ?? 0,
        lastSyncAt: _parseTime(j['last_sync_at']),
      );
}

class ClassRoster {
  final String classId;
  final String week;
  final List<RosterStudent> students;
  const ClassRoster({
    required this.classId,
    required this.week,
    required this.students,
  });

  factory ClassRoster.fromJson(Map<String, dynamic> j) => ClassRoster(
        classId: j['class_id'] as String? ?? '',
        week: j['week'] as String? ?? '',
        students: (j['students'] as List<dynamic>? ?? const [])
            .map((e) => RosterStudent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TopicStat {
  final String topic;
  final int attempts;
  final int correct;
  final int? accuracy;
  const TopicStat({
    required this.topic,
    required this.attempts,
    required this.correct,
    required this.accuracy,
  });

  factory TopicStat.fromJson(Map<String, dynamic> j) => TopicStat(
        topic: j['topic'] as String? ?? '',
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
        correct: (j['correct'] as num?)?.toInt() ?? 0,
        accuracy: (j['accuracy'] as num?)?.toInt(),
      );
}

class StudentDetail {
  final String? name;
  final int streakDays;
  final int sessions;
  final int totalAttempts;
  final int totalCorrect;
  final int? accuracy;
  final List<TopicStat> topics;
  const StudentDetail({
    required this.name,
    required this.streakDays,
    required this.sessions,
    required this.totalAttempts,
    required this.totalCorrect,
    required this.accuracy,
    required this.topics,
  });

  factory StudentDetail.fromJson(Map<String, dynamic> j) {
    final s = j['student'] as Map<String, dynamic>? ?? const {};
    final t = j['totals'] as Map<String, dynamic>? ?? const {};
    return StudentDetail(
      name: s['name'] as String?,
      streakDays: (s['streak_days'] as num?)?.toInt() ?? 0,
      sessions: (s['sessions'] as num?)?.toInt() ?? 0,
      totalAttempts: (t['attempts'] as num?)?.toInt() ?? 0,
      totalCorrect: (t['correct'] as num?)?.toInt() ?? 0,
      accuracy: (t['accuracy'] as num?)?.toInt(),
      topics: (j['topics'] as List<dynamic>? ?? const [])
          .map((e) => TopicStat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

DateTime? _parseTime(dynamic v) =>
    v is String ? DateTime.tryParse(v) : null;

/// Thin HTTP client for the backend endpoints. Knows nothing about storage
/// or scheduling — that's [SyncService]'s job.
class ApiClient {
  final String baseUrl;
  final http.Client _http;
  final Duration timeout;

  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 10),
  }) : _http = httpClient ?? http.Client();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<AuthResult> authenticate({
    required String phone,
    String? name,
    String? schoolCode,
    String? enrollCode,
  }) async {
    final res = await _post('/auth', {
      'phone': phone,
      if (name != null && name.isNotEmpty) 'name': name,
      if (schoolCode != null && schoolCode.isNotEmpty) 'school_code': schoolCode,
      if (enrollCode != null && enrollCode.isNotEmpty) 'enroll_code': enrollCode,
    });
    final body = _decode(res);
    return AuthResult(
      token: body['token'] as String,
      studentId: (body['student'] as Map<String, dynamic>)['id'] as String,
    );
  }

  // ── Teacher dashboard ──────────────────────────────────────────────────────

  /// Teacher login by phone + password; returns a teacher bearer token.
  Future<String> teacherAuthenticate({
    required String phone,
    required String password,
  }) async {
    final res = await _post('/teacher/auth', {'phone': phone, 'password': password});
    return _decode(res)['token'] as String;
  }

  Future<List<TeacherClass>> teacherClasses({required String token}) async {
    final body = await _get('/teacher/classes', token: token);
    return (body['classes'] as List<dynamic>? ?? const [])
        .map((e) => TeacherClass.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ClassRoster> classRoster({
    required String token,
    required String classId,
  }) async {
    final body = await _get('/teacher/classes/$classId', token: token);
    return ClassRoster.fromJson(body);
  }

  Future<StudentDetail> studentDetail({
    required String token,
    required String studentId,
  }) async {
    final body = await _get('/teacher/students/$studentId', token: token);
    return StudentDetail.fromJson(body);
  }

  Future<Map<String, dynamic>> _get(String path, {required String token}) async {
    final http.Response res;
    try {
      res = await _http.get(
        _uri(path),
        headers: {'authorization': 'Bearer $token'},
      ).timeout(timeout);
    } catch (e) {
      throw ApiException('network error: $e');
    }
    return _decode(res);
  }

  Future<void> sync({required String token, required SyncPayload payload}) async {
    final res = await _post('/sync', payload.toJson(), token: token);
    _decode(res); // throws on non-2xx
  }

  Future<Leaderboard> leaderboard({required String token}) async {
    final http.Response res;
    try {
      res = await _http.get(
        _uri('/leaderboard'),
        headers: {'authorization': 'Bearer $token'},
      ).timeout(timeout);
    } catch (e) {
      throw ApiException('network error: $e');
    }
    return Leaderboard.fromJson(_decode(res));
  }

  /// Returns the latest content version the server offers (0 if none).
  Future<int> latestContentVersion() async {
    final http.Response res;
    try {
      res = await _http.get(_uri('/content/version')).timeout(timeout);
    } catch (e) {
      throw ApiException('network error: $e');
    }
    final body = _decode(res);
    return (body['latest_version'] as num?)?.toInt() ?? 0;
  }

  Future<http.Response> _post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      return await _http
          .post(
            _uri(path),
            headers: {
              'content-type': 'application/json',
              if (token != null) 'authorization': 'Bearer $token',
            },
            body: json.encode(body),
          )
          .timeout(timeout);
    } catch (e) {
      throw ApiException('network error: $e');
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        res.body.isEmpty ? 'request failed' : res.body,
        statusCode: res.statusCode,
      );
    }
    if (res.body.isEmpty) return const {};
    return json.decode(res.body) as Map<String, dynamic>;
  }

  void close() => _http.close();
}
