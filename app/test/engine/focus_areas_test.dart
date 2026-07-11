import 'package:flutter_test/flutter_test.dart';
import 'package:ezpzstudy/data/models/topic_map.dart';
import 'package:ezpzstudy/engine/routing/focus_areas.dart';
import 'package:ezpzstudy/engine/scoring/predicted_score.dart';

TopicMap _map() => const TopicMap(
      schemaVersion: 'test',
      remedialLabels: {},
      topics: [
        TopicInfo(id: 'tense', labelEn: 'Tense', paper: '2nd', weight: 10, remedial: []),
        TopicInfo(id: 'voice', labelEn: 'Voice', paper: '2nd', weight: 5, remedial: []),
        TopicInfo(id: 'prep', labelEn: 'Preposition', paper: '2nd', weight: 4, remedial: []),
      ],
    );

void main() {
  const router = FocusAreaRouter();

  test('only weak, assessed topics become focus areas', () {
    final queue = router.buildQueue(_map(), {
      'tense': const TopicStat(attempts: 10, correct: 3), // 30% -> weak
      'voice': const TopicStat(attempts: 10, correct: 9), // 90% -> strong
      // prep not assessed -> excluded
    });
    expect(queue.map((f) => f.topicId), ['tense']);
  });

  test('unassessed topics never appear', () {
    final queue = router.buildQueue(_map(), {});
    expect(queue, isEmpty);
  });

  test('ranks a weak high-marks topic above a weak low-marks topic', () {
    final queue = router.buildQueue(_map(), {
      'tense': const TopicStat(attempts: 10, correct: 4), // 40%, weight 10
      'prep': const TopicStat(attempts: 10, correct: 4), // 40%, weight 4
    });
    expect(queue.first.topicId, 'tense');
    expect(queue.last.topicId, 'prep');
  });

  test('a weaker low-marks topic can still outrank a slightly-weak high-marks one',
      () {
    final queue = router.buildQueue(_map(), {
      'tense': const TopicStat(attempts: 10, correct: 5), // 50% weight10 -> (0.5)*(11)=5.5
      'prep': const TopicStat(attempts: 10, correct: 0), // 0% weight4 -> (1.0)*(5)=5.0
    });
    expect(queue.first.topicId, 'tense'); // 5.5 > 5.0
  });

  test('scoreOutOfTen reflects accuracy', () {
    final queue = router.buildQueue(_map(), {
      'tense': const TopicStat(attempts: 10, correct: 3),
    });
    expect(queue.single.scoreOutOfTen, 3);
  });

  group('clearing', () {
    test('needs both enough attempts and high enough accuracy', () {
      expect(router.isCleared(const TopicStat(attempts: 6, correct: 5)), isTrue); // 83%
      expect(router.isCleared(const TopicStat(attempts: 3, correct: 3)), isFalse); // too few
      expect(router.isCleared(const TopicStat(attempts: 10, correct: 6)), isFalse); // 60% < 70%
      expect(router.isCleared(null), isFalse);
    });
  });

  group('allClear gate', () {
    test('false while any assessed topic is weak', () {
      final all = router.allClear(_map(), {
        'tense': const TopicStat(attempts: 10, correct: 9),
        'voice': const TopicStat(attempts: 10, correct: 2),
      });
      expect(all, isFalse);
    });

    test('true when every assessed topic is above the weak threshold', () {
      final all = router.allClear(_map(), {
        'tense': const TopicStat(attempts: 10, correct: 9),
        'voice': const TopicStat(attempts: 10, correct: 8),
      });
      expect(all, isTrue);
    });

    test('false when nothing has been assessed', () {
      expect(router.allClear(_map(), {}), isFalse);
    });
  });
}
