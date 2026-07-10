import 'package:flutter/material.dart';

import '../../../data/models/question.dart';
import '../../../data/models/question_data.dart';
import '../../../engine/scoring/scoring_engine.dart';
import '../../../theme/app_theme.dart';
import 'answer_renderer.dart';
import 'matching_renderer.dart';
import 'mcq_renderer.dart';
import 'text_answer_renderer.dart';
import 'word_bank_renderer.dart';

/// Comprehension set: a passage followed by its nested sub-questions, each
/// rendered with its own auto-graded renderer. The set scores correct only if
/// every sub-question is correct.
class ComprehensionRenderer extends StatefulWidget {
  final ComprehensionSetData data;
  final RendererArgs args;
  const ComprehensionRenderer(
      {super.key, required this.data, required this.args});

  @override
  State<ComprehensionRenderer> createState() => ComprehensionRendererState();
}

class ComprehensionRendererState extends State<ComprehensionRenderer>
    implements AutoGraded {
  final List<GlobalKey> _keys = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.data.subQuestions.length; i++) {
      _keys.add(GlobalKey());
    }
  }

  List<AutoGraded> get _children => _keys
      .map((k) => k.currentState)
      .whereType<AutoGraded>()
      .toList();

  @override
  bool get canSubmit {
    final children = _children;
    if (children.length != widget.data.subQuestions.length) return false;
    return children.every((c) => c.canSubmit);
  }

  @override
  ScoreResult score() {
    var allCorrect = true;
    final answers = <String>[];
    for (final child in _children) {
      final r = child.score();
      if (!r.isCorrect) allCorrect = false;
      answers.addAll(r.correctAnswers);
    }
    return ScoreResult(
      allCorrect ? ScoreVerdict.correct : ScoreVerdict.incorrect,
      correctAnswers: answers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(widget.data.passageEn,
              style: const TextStyle(fontSize: 16, height: 1.6)),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < widget.data.subQuestions.length; i++) ...[
          Text('${i + 1}.',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.black45)),
          const SizedBox(height: 6),
          _buildSub(widget.data.subQuestions[i], _keys[i]),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildSub(SubQuestion sub, GlobalKey key) {
    switch (sub.type) {
      case QuestionType.mcq:
        return McqRenderer(key: key, data: sub.data as McqData, args: widget.args);
      case QuestionType.fillInWordBank:
        return WordBankRenderer(
            key: key, data: sub.data as FillInWordBankData, args: widget.args);
      case QuestionType.fillInOpen:
        return TextAnswerRenderer.fillInOpen(
            key: key, data: sub.data as FillInOpenData, args: widget.args);
      case QuestionType.matching:
        return MatchingRenderer(
            key: key, data: sub.data as MatchingData, args: widget.args);
      default:
        return const SizedBox.shrink();
    }
  }
}
