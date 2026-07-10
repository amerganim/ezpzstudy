import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezpzstudy/app_services.dart';
import 'package:ezpzstudy/data/db/database.dart';
import 'package:ezpzstudy/data/models/question.dart';
import 'package:ezpzstudy/l10n/strings_bn.dart';
import 'package:ezpzstudy/ui/session/feedback_panel.dart';
import 'package:ezpzstudy/ui/session/session_screen.dart';

Future<void> _loadPack(AppDatabase db) async {
  final pack = json.decode(
          await File('assets/content/content_pack_v1.json').readAsString())
      as List<dynamic>;
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
  late AppServices services;

  setUp(() async {
    services = AppServices.withDatabase(AppDatabase(NativeDatabase.memory()));
    await _loadPack(services.db);
  });

  tearDown(() async {
    await services.db.close();
  });

  Future<void> pumpSession(WidgetTester tester, List<Question> questions) async {
    // Tall surface so the lazily-built ListView instantiates every child
    // (question, options, and the feedback panel) without needing to scroll.
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      AppServicesScope(
        services: services,
        child: MaterialApp(
          home: SessionScreen(topic: 'tense', questions: questions),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('answering an MCQ correctly shows the correct feedback',
      (tester) async {
    // The tense MCQ p2.mcq.tense-01 has correct option C.
    final q = await services.questions.byId('p2.mcq.tense-01');
    expect(q, isNotNull);
    await pumpSession(tester, [q!]);

    // Check button disabled until an option is chosen.
    final checkButton = find.widgetWithText(FilledButton, Bn.checkAnswer);
    expect(tester.widget<FilledButton>(checkButton).onPressed, isNull);

    // Select the correct option (C) and check.
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    await tester.tap(checkButton);
    await tester.pumpAndSettle();

    expect(find.byType(FeedbackPanel), findsOneWidget);
    expect(find.text(Bn.correct), findsOneWidget);
    // A single-question session shows "finish" next.
    expect(find.widgetWithText(FilledButton, Bn.finish), findsOneWidget);
  });

  testWidgets('answering an MCQ wrongly reveals the answer and rule',
      (tester) async {
    final q = await services.questions.byId('p2.mcq.tense-01');
    await pumpSession(tester, [q!]);

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, Bn.checkAnswer));
    await tester.pumpAndSettle();

    expect(find.text(Bn.incorrect), findsOneWidget);
    // The correct-answer label appears on a wrong answer.
    expect(find.text(Bn.correctAnswerIs), findsOneWidget);
  });

  testWidgets('a correct answer records a topic-progress attempt',
      (tester) async {
    final q = await services.questions.byId('p2.mcq.tense-01');
    await pumpSession(tester, [q!]);
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, Bn.checkAnswer));
    await tester.pumpAndSettle();

    final progress = await services.db.allProgress();
    final tense = progress.firstWhere((p) => p.topic == 'tense');
    expect(tense.attempts, 1);
    expect(tense.correct, 1);
  });
}
