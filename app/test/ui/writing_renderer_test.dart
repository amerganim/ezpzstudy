import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezpzstudy/data/models/question_data.dart';
import 'package:ezpzstudy/engine/scoring/scoring_engine.dart';
import 'package:ezpzstudy/l10n/strings_bn.dart';
import 'package:ezpzstudy/theme/app_theme.dart';
import 'package:ezpzstudy/ui/session/renderers/writing_renderer.dart';

WritingPromptData _data() => const WritingPromptData(
      writingType: 'paragraph',
      promptEn: 'Write about your school.',
      wordLimit: WordLimit(min: 150, max: 200),
      modelAnswerEn: 'My school is a nice place ...',
      rubricChecklist: [
        RubricItem(id: 'R1', criterionBn: 'topic sentence দিয়েছি'),
        RubricItem(id: 'R2', criterionBn: 'কয়েকটি পয়েন্ট দিয়েছি'),
        RubricItem(id: 'R3', criterionBn: 'concluding sentence দিয়েছি'),
      ],
    );

Future<void> _pump(WidgetTester tester, {ScoreResult? Function()? onSubmit}) {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: WritingRenderer(
            data: _data(),
            submitted: false,
            onSubmit: (_) => onSubmit?.call(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('model answer stays hidden until enough is written',
      (tester) async {
    await _pump(tester);

    // Reveal button present but disabled; model answer not shown yet.
    final revealBtn = find.widgetWithText(FilledButton, Bn.showModelAnswer);
    expect(revealBtn, findsOneWidget);
    expect(tester.widget<FilledButton>(revealBtn).onPressed, isNull);
    expect(find.text('নমুনা উত্তর'), findsNothing);

    // A too-short attempt keeps it disabled.
    await tester.enterText(find.byType(TextField), 'too short');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(revealBtn).onPressed, isNull);

    // A real attempt (>= 15 words) enables the reveal.
    await tester.enterText(
        find.byType(TextField), List.filled(16, 'word').join(' '));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
              find.widgetWithText(FilledButton, Bn.showModelAnswer))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('rubric is ticked after reveal and drives the score, then submits',
      (tester) async {
    ScoreResult? submitted;
    await _pump(tester, onSubmit: () {
      submitted = ScoreResult.selfCheck;
      return submitted;
    });

    await tester.enterText(
        find.byType(TextField), List.filled(20, 'word').join(' '));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, Bn.showModelAnswer));
    await tester.pumpAndSettle();

    // Model answer + comparison prompt now visible; no rubric ticked yet.
    expect(find.text('নমুনা উত্তর'), findsOneWidget);
    expect(find.text('${Bn.digits(0)} / ${Bn.digits(3)}'), findsOneWidget);

    // Tick two of three criteria -> score reflects it.
    final checks = find.byType(CheckboxListTile);
    await tester.tap(checks.at(0));
    await tester.tap(checks.at(1));
    await tester.pumpAndSettle();
    expect(find.text('${Bn.digits(2)} / ${Bn.digits(3)}'), findsOneWidget);

    // Finish submits a self-check result.
    await tester.tap(find.widgetWithText(FilledButton, Bn.doneSelfCheck));
    await tester.pumpAndSettle();
    expect(submitted, isNotNull);
    expect(submitted!.verdict, ScoreVerdict.selfCheck);
  });
}
