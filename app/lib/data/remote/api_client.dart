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
  }) async {
    final res = await _post('/auth', {
      'phone': phone,
      if (name != null && name.isNotEmpty) 'name': name,
      if (schoolCode != null && schoolCode.isNotEmpty) 'school_code': schoolCode,
    });
    final body = _decode(res);
    return AuthResult(
      token: body['token'] as String,
      studentId: (body['student'] as Map<String, dynamic>)['id'] as String,
    );
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
