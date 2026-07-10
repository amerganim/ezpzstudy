import 'dart:convert';

import 'db/database.dart';
import 'models/question.dart';
import 'models/question_data.dart';

/// A topic plus how many practiceable (non-flashcard) questions it has.
class TopicSummary {
  final String topic;
  final int questionCount;
  const TopicSummary({required this.topic, required this.questionCount});
}

/// Reads questions out of the local store and rehydrates them into the parsed
/// [Question] model the UI and scoring engine work with.
class QuestionRepository {
  final AppDatabase db;
  const QuestionRepository(this.db);

  Question _fromRow(QuestionRow row) {
    final type = QuestionType.fromJson(row.type);
    return Question(
      id: row.id,
      type: type,
      paper: row.paper,
      topic: row.topic,
      subtopic: row.subtopic,
      difficulty: Difficulty.fromJson(row.difficulty),
      marksWeight: row.marksWeight,
      tags: (json.decode(row.tagsJson) as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      instructionBn: row.instructionBn,
      explanationBn: row.explanationBn,
      reviewStatus: row.reviewStatus,
      author: row.author,
      data: QuestionData.fromJson(
          type, json.decode(row.dataJson) as Map<String, dynamic>),
    );
  }

  Future<List<String>> topics() => db.distinctTopics();

  Future<List<Question>> forTopic(String topic) async {
    final rows = await db.questionsForTopic(topic);
    return rows.map(_fromRow).toList();
  }

  /// Topics that have at least one non-flashcard practice question, with the
  /// count of such questions. Flashcards are practiced via the SRS screen, not
  /// a topic session, so they're excluded here.
  Future<List<TopicSummary>> practiceTopics() async {
    final rows = await db.select(db.questions).get();
    final counts = <String, int>{};
    for (final row in rows) {
      if (row.type == 'flashcard') continue;
      counts.update(row.topic, (v) => v + 1, ifAbsent: () => 1);
    }
    final summaries = counts.entries
        .map((e) => TopicSummary(topic: e.key, questionCount: e.value))
        .toList()
      ..sort((a, b) => a.topic.compareTo(b.topic));
    return summaries;
  }

  /// Builds a practice set for a topic: up to [limit] non-flashcard questions,
  /// shuffled so repeated sessions vary.
  Future<List<Question>> practiceSet(String topic, {int limit = 10}) async {
    final all = await forTopic(topic);
    final practiceable =
        all.where((q) => q.type != QuestionType.flashcard).toList()..shuffle();
    return practiceable.take(limit).toList();
  }

  Future<List<Question>> ofType(QuestionType type) async {
    final rows = await db.questionsOfType(_typeToJson(type));
    return rows.map(_fromRow).toList();
  }

  Future<Question?> byId(String id) async {
    final row = await (db.select(db.questions)
          ..where((q) => q.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  String _typeToJson(QuestionType type) {
    switch (type) {
      case QuestionType.flashcard:
        return 'flashcard';
      case QuestionType.mcq:
        return 'mcq';
      case QuestionType.fillInWordBank:
        return 'fill_in_word_bank';
      case QuestionType.fillInOpen:
        return 'fill_in_open';
      case QuestionType.matching:
        return 'matching';
      case QuestionType.rearranging:
        return 'rearranging';
      case QuestionType.grammarTransformation:
        return 'grammar_transformation';
      case QuestionType.comprehensionSet:
        return 'comprehension_set';
      case QuestionType.writingPrompt:
        return 'writing_prompt';
    }
  }
}
