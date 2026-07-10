import 'package:drift/drift.dart';

import '../engine/srs/sm2.dart';
import 'db/database.dart';
import 'models/question.dart';
import 'models/question_data.dart';
import 'question_repository.dart';

/// A flashcard due for review, with its current SRS state.
class DueCard {
  final Question question;
  final Sm2State state;
  const DueCard({required this.question, required this.state});

  FlashcardData get flashcard => question.data as FlashcardData;
}

/// Builds the flashcard review queue and persists SM-2 results. A card is due
/// if it has never been reviewed (new) or its scheduled review date has passed.
class FlashcardRepository {
  final AppDatabase db;
  final QuestionRepository questions;
  final Sm2Scheduler scheduler;

  FlashcardRepository(this.db, this.questions,
      {this.scheduler = const Sm2Scheduler()});

  Future<List<DueCard>> dueQueue({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final cards = await questions.ofType(QuestionType.flashcard);
    final due = <DueCard>[];
    for (final card in cards) {
      final srs = await db.srsFor(card.id);
      if (srs == null) {
        // Never reviewed -> new card, due immediately.
        due.add(DueCard(question: card, state: Sm2State.initial));
      } else {
        final dueDate = _dayOnly(srs.dueDate);
        if (!dueDate.isAfter(_dayOnly(today))) {
          due.add(DueCard(
            question: card,
            state: Sm2State(
              easeFactor: srs.easeFactor,
              repetitions: srs.repetitions,
              intervalDays: srs.intervalDays,
            ),
          ));
        }
      }
    }
    return due;
  }

  Future<void> grade(DueCard card, RecallGrade grade, {DateTime? now}) async {
    final reviewedOn = now ?? DateTime.now();
    final updated = scheduler.review(card.state, grade);
    final dueDate = scheduler.nextReview(updated, reviewedOn);
    await db.upsertSrs(FlashcardSrsCompanion(
      questionId: Value(card.question.id),
      easeFactor: Value(updated.easeFactor),
      repetitions: Value(updated.repetitions),
      intervalDays: Value(updated.intervalDays),
      dueDate: Value(dueDate),
    ));
  }

  DateTime _dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
