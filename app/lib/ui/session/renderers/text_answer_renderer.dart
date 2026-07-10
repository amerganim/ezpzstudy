import 'package:flutter/material.dart';

import '../../../data/models/question_data.dart';
import '../../../engine/scoring/scoring_engine.dart';
import '../../../l10n/strings_bn.dart';
import '../../../theme/app_theme.dart';
import 'answer_renderer.dart';

/// Shared renderer for the two free-text, fuzzy-scored types: open fill-in and
/// grammar transformation. A [prompt] line is shown above a single text field.
class TextAnswerRenderer extends StatefulWidget {
  final String prompt;
  final RendererArgs args;
  final ScoreResult Function(String answer) scorer;

  const TextAnswerRenderer({
    super.key,
    required this.prompt,
    required this.args,
    required this.scorer,
  });

  /// For open fill-in.
  factory TextAnswerRenderer.fillInOpen({
    Key? key,
    required FillInOpenData data,
    required RendererArgs args,
  }) =>
      TextAnswerRenderer(
        key: key,
        prompt: data.sentenceEn,
        args: args,
        scorer: (a) => args.engine.scoreFillInOpen(data, a),
      );

  /// For grammar transformation.
  factory TextAnswerRenderer.grammar({
    Key? key,
    required GrammarTransformationData data,
    required RendererArgs args,
  }) =>
      TextAnswerRenderer(
        key: key,
        prompt: data.originalSentenceEn,
        args: args,
        scorer: (a) => args.engine.scoreGrammarTransformation(data, a),
      );

  @override
  State<TextAnswerRenderer> createState() => TextAnswerRendererState();
}

class TextAnswerRendererState extends State<TextAnswerRenderer>
    implements AutoGraded {
  final _controller = TextEditingController();

  @override
  bool get canSubmit => _controller.text.trim().isNotEmpty;

  @override
  ScoreResult score() => widget.scorer(_controller.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.args.result;
    final answered = result != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.prompt,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          enabled: !answered,
          minLines: 1,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => widget.args.onChanged(),
          decoration: InputDecoration(
            hintText: Bn.yourAnswer,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.accent, width: 2),
            ),
          ),
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
