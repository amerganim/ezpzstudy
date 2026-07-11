import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezpzstudy/data/db/database.dart';
import 'package:ezpzstudy/data/question_repository.dart';
import 'package:ezpzstudy/data/models/question.dart';
import 'package:ezpzstudy/data/models/question_data.dart';

/// Loads the real content pack file directly into an in-memory DB (bypassing
/// rootBundle, which isn't available in a plain unit test) to prove the row
/// round-trip and model rehydration work against actual shipped content.
Future<void> loadPackFromFile(AppDatabase db) async {
  final packFile = File('assets/content/content_pack_v2.json');
  final pack = json.decode(await packFile.readAsString()) as List<dynamic>;
  await db.batch((batch) {
    for (final entry in pack) {
      final q = entry as Map<String, dynamic>;
      batch.insert(
        db.questions,
        QuestionsCompanion.insert(
          id: q['id'] as String,
          type: q['type'] as String,
          paper: q['paper'] as String,
          topic: q['topic'] as String,
          subtopic: Value(q['subtopic'] as String?),
          difficulty: q['difficulty'] as String,
          marksWeight: (q['marks_weight'] as num).toDouble(),
          tagsJson: Value(json.encode(q['tags'] ?? const [])),
          instructionBn: q['instruction_bn'] as String,
          explanationBn: q['explanation_bn'] as String,
          reviewStatus: q['review_status'] as String,
          author: q['author'] as String,
          dataJson: json.encode(q['data']),
        ),
      );
    }
  });
}

void main() {
  late AppDatabase db;
  late QuestionRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = QuestionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('loads the whole content pack into the store', () async {
    await loadPackFromFile(db);
    // The shipped HSC pack; assert a healthy floor rather than an exact count
    // so authoring more content doesn't break the test.
    expect(await db.questionCount(), greaterThanOrEqualTo(150));
  });

  test('every stored question rehydrates into a typed model', () async {
    await loadPackFromFile(db);
    final topics = await repo.topics();
    var total = 0;
    for (final topic in topics) {
      final questions = await repo.forTopic(topic);
      total += questions.length;
      // Touching .data forces the sealed-type parse for every question.
      for (final q in questions) {
        expect(q.data, isA<QuestionData>());
      }
    }
    expect(total, await db.questionCount());
  });

  test('flashcards rehydrate with their Bangla meaning', () async {
    await loadPackFromFile(db);
    final cards = await repo.ofType(QuestionType.flashcard);
    expect(cards, isNotEmpty);
    final data = cards.first.data as FlashcardData;
    expect(data.frontEn, isNotEmpty);
    expect(data.backBn, isNotEmpty);
  });

  test('mcq options and correct key survive the round-trip', () async {
    await loadPackFromFile(db);
    final mcqs = await repo.ofType(QuestionType.mcq);
    expect(mcqs, isNotEmpty);
    final data = mcqs.first.data as McqData;
    expect(data.options, isNotEmpty);
    expect(data.correctOption, isNotEmpty);
  });
}
