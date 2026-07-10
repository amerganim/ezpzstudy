import 'package:flutter/material.dart';

import '../../../data/models/question_data.dart';
import '../../../engine/scoring/scoring_engine.dart';
import '../../../theme/app_theme.dart';
import 'answer_renderer.dart';

/// Word-bank fill-in: the sentence (with {{n}} markers) is shown, and each blank
/// is a dropdown constrained to the shared word bank. Exact match against a
/// closed set, so a dropdown is the right control.
class WordBankRenderer extends StatefulWidget {
  final FillInWordBankData data;
  final RendererArgs args;
  const WordBankRenderer({super.key, required this.data, required this.args});

  @override
  State<WordBankRenderer> createState() => WordBankRendererState();
}

class WordBankRendererState extends State<WordBankRenderer>
    implements AutoGraded {
  final Map<String, String> _answers = {};

  @override
  bool get canSubmit =>
      widget.data.blanks.every((b) => _answers.containsKey(b.blankId));

  @override
  ScoreResult score() =>
      widget.args.engine.scoreFillInWordBank(widget.data, _answers);

  @override
  Widget build(BuildContext context) {
    final answered = widget.args.answered;
    final displaySentence =
        widget.data.sentenceEn.replaceAll(RegExp(r'\{\{\d+\}\}'), ' ____ ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(displaySentence,
            style: const TextStyle(fontSize: 20, height: 1.5)),
        const SizedBox(height: 20),
        for (final blank in widget.data.blanks)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BlankDropdown(
              blank: blank,
              words: widget.data.wordBank,
              value: _answers[blank.blankId],
              answered: answered,
              onChanged: answered
                  ? null
                  : (v) {
                      setState(() => _answers[blank.blankId] = v!);
                      widget.args.onChanged();
                    },
            ),
          ),
      ],
    );
  }
}

class _BlankDropdown extends StatelessWidget {
  final Blank blank;
  final List<String> words;
  final String? value;
  final bool answered;
  final ValueChanged<String?>? onChanged;

  const _BlankDropdown({
    required this.blank,
    required this.words,
    required this.value,
    required this.answered,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Color border = Colors.black26;
    if (answered && value != null) {
      final ok = ScoringEngine.normalize(value!) ==
          ScoringEngine.normalize(blank.correctAnswer);
      border = ok ? AppTheme.correct : AppTheme.incorrect;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: border, width: 1.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text('${blank.blankId}.',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: const Text('...'),
                items: [
                  for (final w in words)
                    DropdownMenuItem(value: w, child: Text(w)),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
          if (answered)
            Text(blank.correctAnswer,
                style: const TextStyle(
                    color: AppTheme.correct, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
