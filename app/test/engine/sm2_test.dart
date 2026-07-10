import 'package:flutter_test/flutter_test.dart';
import 'package:ezpzstudy/engine/srs/sm2.dart';

void main() {
  const scheduler = Sm2Scheduler();

  test('first successful review sets interval to 1 day', () {
    final s = scheduler.review(Sm2State.initial, RecallGrade.good);
    expect(s.repetitions, 1);
    expect(s.intervalDays, 1);
  });

  test('second successful review sets interval to 6 days', () {
    var s = scheduler.review(Sm2State.initial, RecallGrade.good);
    s = scheduler.review(s, RecallGrade.good);
    expect(s.repetitions, 2);
    expect(s.intervalDays, 6);
  });

  test('third successful review scales interval by ease factor', () {
    var s = scheduler.review(Sm2State.initial, RecallGrade.good);
    s = scheduler.review(s, RecallGrade.good);
    final before = s.intervalDays;
    s = scheduler.review(s, RecallGrade.good);
    expect(s.repetitions, 3);
    expect(s.intervalDays, greaterThan(before));
  });

  test('a lapse resets repetitions and schedules for tomorrow', () {
    var s = scheduler.review(Sm2State.initial, RecallGrade.good);
    s = scheduler.review(s, RecallGrade.good);
    s = scheduler.review(s, RecallGrade.again);
    expect(s.repetitions, 0);
    expect(s.intervalDays, 1);
  });

  test('ease factor never drops below 1.3', () {
    var s = Sm2State.initial;
    for (var i = 0; i < 10; i++) {
      s = scheduler.review(s, RecallGrade.again);
    }
    expect(s.easeFactor, greaterThanOrEqualTo(1.3));
  });

  test('easy grades raise the ease factor above the starting 2.5', () {
    var s = scheduler.review(Sm2State.initial, RecallGrade.easy);
    s = scheduler.review(s, RecallGrade.easy);
    expect(s.easeFactor, greaterThan(2.5));
  });

  test('nextReview adds the interval in days', () {
    final s = Sm2State(easeFactor: 2.5, repetitions: 2, intervalDays: 6);
    final next = scheduler.nextReview(s, DateTime(2026, 7, 10));
    expect(next, DateTime(2026, 7, 16));
  });
}
