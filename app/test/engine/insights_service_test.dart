import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezpzstudy/data/db/database.dart';
import 'package:ezpzstudy/data/models/topic_map.dart';
import 'package:ezpzstudy/data/progress_repository.dart';
import 'package:ezpzstudy/data/topic_map_repository.dart';
import 'package:ezpzstudy/engine/insights_service.dart';

/// Loads the real compiled topic map from disk (rootBundle isn't available in a
/// plain unit test).
Future<TopicMap> _realTopicMap() async {
  final raw =
      await File('assets/content/topic_map.json').readAsString();
  return TopicMap.fromJson(json.decode(raw) as Map<String, dynamic>);
}

Future<void> _seedProgress(
    AppDatabase db, Map<String, (int correct, int attempts)> byTopic) async {
  for (final entry in byTopic.entries) {
    final (correct, attempts) = entry.value;
    await db.into(db.topicProgress).insert(TopicProgressCompanion.insert(
          topic: entry.key,
          attempts: Value(attempts),
          correct: Value(correct),
        ));
  }
}

void main() {
  late AppDatabase db;
  late InsightsService insights;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final progress = ProgressRepository(db);
    final topicMap = TopicMapRepository()..setForTesting(await _realTopicMap());
    insights = InsightsService(progress: progress, topicMap: topicMap);
  });

  tearDown(() async => db.close());

  test('with no progress, score is unavailable and no focus areas', () async {
    final result = await insights.load();
    expect(result.predictedScore.available, isFalse);
    expect(result.focusAreas, isEmpty);
    expect(result.allClear, isFalse);
    expect(result.diagnosticDone, isFalse);
  });

  test('a weak topic surfaces as a focus area and lowers the score', () async {
    // "p2_preposition" is a real, weighted (5-mark) HSC exam item.
    await _seedProgress(db, {'p2_preposition': (2, 10)}); // 20% accuracy
    final result = await insights.load();
    expect(result.predictedScore.available, isTrue);
    expect(result.predictedScore.percent, 20);
    expect(result.focusAreas.map((f) => f.topicId), contains('p2_preposition'));
    expect(result.allClear, isFalse);
  });

  test('strong performance clears focus areas and unlocks the challenge gate',
      () async {
    await _seedProgress(db, {
      'p2_preposition': (9, 10), // 90%
      'p2_right_form_verb': (8, 10), // 80%
    });
    final result = await insights.load();
    expect(result.focusAreas, isEmpty);
    expect(result.allClear, isTrue);
    expect(result.predictedScore.percent, greaterThanOrEqualTo(80));
  });

  test('the diagnostic-done flag round-trips', () async {
    expect((await insights.load()).diagnosticDone, isFalse);
    await ProgressRepository(db).markDiagnosticDone();
    expect((await insights.load()).diagnosticDone, isTrue);
  });
}
