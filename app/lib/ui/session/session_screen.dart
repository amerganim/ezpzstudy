import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/models/question.dart';
import '../../data/models/question_data.dart';
import '../../engine/scoring/scoring_engine.dart';
import '../../engine/session/session_controller.dart';
import '../../l10n/strings_bn.dart';
import '../../theme/app_theme.dart';
import 'feedback_panel.dart';
import 'renderers/answer_renderer.dart';
import 'renderers/comprehension_renderer.dart';
import 'renderers/matching_renderer.dart';
import 'renderers/mcq_renderer.dart';
import 'renderers/rearranging_renderer.dart';
import 'renderers/text_answer_renderer.dart';
import 'renderers/word_bank_renderer.dart';
import 'renderers/writing_renderer.dart';
import 'session_summary_screen.dart';

/// One 10-question practice session: progress bar, the current question, instant
/// per-question feedback, then a summary.
class SessionScreen extends StatefulWidget {
  final String topic;
  final List<Question> questions;
  const SessionScreen(
      {super.key, required this.topic, required this.questions});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final SessionController _controller;
  late GlobalKey _rendererKey;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _controller = SessionController(
      questions: widget.questions,
      progress: AppServices.of(context).progress,
    );
    _rendererKey = GlobalKey();
    _scheduleCanSubmitRefresh();
  }

  void _scheduleCanSubmitRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCanSubmit());
  }

  /// The current renderer's [AutoGraded] interface, or null for self-managed
  /// renderers (writing) or before the first frame builds the renderer.
  AutoGraded? _gradedState() {
    final state = _rendererKey.currentState;
    // AutoGraded is not a subtype of State, so `is` does not promote — cast
    // explicitly after the guard.
    return state is AutoGraded ? state as AutoGraded : null;
  }

  void _refreshCanSubmit() {
    final can = _gradedState()?.canSubmit ?? false;
    if (can != _canSubmit && mounted) {
      setState(() => _canSubmit = can);
    }
  }

  Future<void> _handleSubmit(ScoreResult result) async {
    await _controller.submit(result);
    if (mounted) setState(() {});
  }

  void _check() {
    final graded = _gradedState();
    if (graded != null && graded.canSubmit) {
      _handleSubmit(graded.score());
    }
  }

  void _next() {
    if (_controller.isLastQuestion) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SessionSummaryScreen(
            topic: widget.topic,
            correct: _controller.correctCount,
            total: _controller.total,
          ),
        ),
      );
      return;
    }
    _controller.next();
    setState(() {
      _rendererKey = GlobalKey();
      _canSubmit = false;
    });
    _scheduleCanSubmitRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final engine = AppServices.of(context).scoring;
    final q = _controller.current;
    final result = _controller.currentResult;
    final args = RendererArgs(
      engine: engine,
      result: result,
      onChanged: _refreshCanSubmit,
    );
    final isWriting = q.type == QuestionType.writingPrompt;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${Bn.questionOf} ${Bn.digits(_controller.currentIndex + 1)} / ${Bn.digits(_controller.total)}',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_controller.currentIndex + 1) / _controller.total,
            backgroundColor: Colors.black12,
            color: AppTheme.accent,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _InstructionChip(text: q.instructionBn),
          const SizedBox(height: 16),
          _buildRenderer(q, args, isWriting),
          if (result != null && result.verdict != ScoreVerdict.selfCheck) ...[
            const SizedBox(height: 20),
            FeedbackPanel(result: result, explanationBn: q.explanationBn),
          ],
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isWriting, result),
    );
  }

  Widget _buildBottomBar(bool isWriting, ScoreResult? result) {
    // Writing is self-managed: no "check" button; show Next only after submit.
    if (isWriting && result == null) return const SizedBox.shrink();

    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: result == null
          ? FilledButton(
              onPressed: _canSubmit ? _check : null,
              child: const Text(Bn.checkAnswer),
            )
          : FilledButton(
              onPressed: _next,
              child: Text(
                  _controller.isLastQuestion ? Bn.finish : Bn.nextQuestion),
            ),
    );
  }

  Widget _buildRenderer(Question q, RendererArgs args, bool isWriting) {
    switch (q.type) {
      case QuestionType.mcq:
        return McqRenderer(key: _rendererKey, data: q.data as McqData, args: args);
      case QuestionType.fillInOpen:
        return TextAnswerRenderer.fillInOpen(
            key: _rendererKey, data: q.data as FillInOpenData, args: args);
      case QuestionType.grammarTransformation:
        return TextAnswerRenderer.grammar(
            key: _rendererKey,
            data: q.data as GrammarTransformationData,
            args: args);
      case QuestionType.fillInWordBank:
        return WordBankRenderer(
            key: _rendererKey, data: q.data as FillInWordBankData, args: args);
      case QuestionType.matching:
        return MatchingRenderer(
            key: _rendererKey, data: q.data as MatchingData, args: args);
      case QuestionType.rearranging:
        return RearrangingRenderer(
            key: _rendererKey, data: q.data as RearrangingData, args: args);
      case QuestionType.comprehensionSet:
        return ComprehensionRenderer(
            key: _rendererKey, data: q.data as ComprehensionSetData, args: args);
      case QuestionType.writingPrompt:
        return WritingRenderer(
          key: _rendererKey,
          data: q.data as WritingPromptData,
          submitted: args.answered,
          onSubmit: _handleSubmit,
        );
      case QuestionType.flashcard:
        // Flashcards are practiced via the SRS screen, never in a topic session.
        return const SizedBox.shrink();
    }
  }
}

class _InstructionChip extends StatelessWidget {
  final String text;
  const _InstructionChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentDark)),
    );
  }
}
