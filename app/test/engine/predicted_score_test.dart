import 'package:flutter_test/flutter_test.dart';
import 'package:ezpzstudy/data/models/topic_map.dart';
import 'package:ezpzstudy/engine/scoring/predicted_score.dart';

TopicMap _map() => const TopicMap(
      schemaVersion: 'test',
      remedialLabels: {},
      topics: [
        TopicInfo(id: 'tense', labelEn: 'Tense', paper: '2nd', weight: 10, remedial: []),
        TopicInfo(id: 'voice', labelEn: 'Voice', paper: '2nd', weight: 5, remedial: []),
        TopicInfo(id: 'vocab', labelEn: 'Vocabulary', paper: 'both', weight: 0, remedial: []),
      ],
    );

void main() {
  const engine = PredictedScoreEngine();

  test('no assessed topics -> score unavailable', () {
    final s = engine.compute(_map(), {});
    expect(s.available, isFalse);
    expect(s.percent, 0);
  });

  test('projects weighted accuracy over assessed topics only', () {
    // tense 8/10 = 80% on weight 10; voice not assessed.
    final s = engine.compute(_map(), {
      'tense': const TopicStat(attempts: 10, correct: 8),
    });
    expect(s.available, isTrue);
    expect(s.percent, 80);
    expect(s.assessedWeight, 10);
    // coverage: 10 of (10+5)=15 scoring weight assessed.
    expect(s.coverage, closeTo(10 / 15, 1e-9));
  });

  test('combines multiple topics by weight', () {
    // tense 100% (w10) + voice 0% (w5) => 10 earned / 15 assessed = 67%.
    final s = engine.compute(_map(), {
      'tense': const TopicStat(attempts: 5, correct: 5),
      'voice': const TopicStat(attempts: 5, correct: 0),
    });
    expect(s.percent, 67);
    expect(s.coverage, closeTo(1.0, 1e-9)); // all scoring weight assessed
  });

  test('weight-0 topics never affect the projection', () {
    final s = engine.compute(_map(), {
      'vocab': const TopicStat(attempts: 10, correct: 3),
    });
    // vocab has weight 0 -> nothing assessed toward the board score.
    expect(s.available, isFalse);
  });

  test('higher-weight topic dominates the projection', () {
    final highWeightGood = engine.compute(_map(), {
      'tense': const TopicStat(attempts: 10, correct: 9), // 90% on w10
      'voice': const TopicStat(attempts: 10, correct: 2), // 20% on w5
    });
    // Weighted: (0.9*10 + 0.2*5)/15 = (9+1)/15 = 66.7% -> 67
    expect(highWeightGood.percent, 67);
  });
}
