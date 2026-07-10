// SM-2 spaced-repetition scheduling for vocabulary flashcards.
//
// A simplified, all-local implementation of the classic SuperMemo-2 algorithm.
// The student self-grades each recall; we store an ease factor, the repetition
// count, and the current interval (in days), and compute the next review date.
// Cheap to build, disproportionate learning gain.

/// The persisted scheduling state for one flashcard.
class Sm2State {
  /// Ease factor; starts at 2.5 and never drops below 1.3.
  final double easeFactor;

  /// Number of consecutive successful recalls.
  final int repetitions;

  /// Current interval in whole days until the next review.
  final int intervalDays;

  const Sm2State({
    this.easeFactor = 2.5,
    this.repetitions = 0,
    this.intervalDays = 0,
  });

  /// A brand-new, never-reviewed card.
  static const Sm2State initial = Sm2State();
}

/// Recall quality grades the UI offers the student. Kept coarse (3 buttons)
/// rather than SM-2's full 0-5 so a weak student isn't asked to introspect
/// finely; each maps to an SM-2 quality value.
enum RecallGrade {
  again, // couldn't recall -> quality 2 (a lapse)
  good, // recalled with some effort -> quality 4
  easy; // instant recall -> quality 5

  int get quality {
    switch (this) {
      case RecallGrade.again:
        return 2;
      case RecallGrade.good:
        return 4;
      case RecallGrade.easy:
        return 5;
    }
  }
}

class Sm2Scheduler {
  const Sm2Scheduler();

  /// Applies one recall result to [state] and returns the updated state.
  ///
  /// Quality < 3 is a lapse: repetitions reset and the card is seen again
  /// tomorrow. Quality >= 3 advances the interval per SM-2.
  Sm2State review(Sm2State state, RecallGrade grade) {
    final q = grade.quality;

    // Update the ease factor (same formula as classic SM-2), clamped at 1.3.
    var ef = state.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (ef < 1.3) ef = 1.3;

    if (q < 3) {
      // Lapse: relearn from the start, review again tomorrow.
      return Sm2State(easeFactor: ef, repetitions: 0, intervalDays: 1);
    }

    final reps = state.repetitions + 1;
    final int interval;
    if (reps == 1) {
      interval = 1;
    } else if (reps == 2) {
      interval = 6;
    } else {
      interval = (state.intervalDays * ef).round();
    }

    return Sm2State(easeFactor: ef, repetitions: reps, intervalDays: interval);
  }

  /// The next review date given the [state] and the date the review happened.
  DateTime nextReview(Sm2State state, DateTime reviewedOn) =>
      DateTime(reviewedOn.year, reviewedOn.month, reviewedOn.day)
          .add(Duration(days: state.intervalDays));
}
