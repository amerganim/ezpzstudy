import 'package:flutter/material.dart';

import '../../../data/models/question_data.dart';
import '../../../engine/scoring/scoring_engine.dart';
import '../../../l10n/strings_bn.dart';
import '../../../theme/app_theme.dart';

/// Writing prompt: not auto-scored, but self-checked *honestly*.
///
/// Flow (designed against the pilot's expected failure mode — students marking
/// themselves correct without checking):
///   1. The student must actually write an attempt (a minimum number of words)
///      before the model answer can be revealed.
///   2. Only then is the model answer shown.
///   3. The rubric is ticked AFTER seeing the model — a genuine comparison, not
///      a promise made up front — with a live "you met X / N points" score.
///
/// Self-managed: it calls [onSubmit] itself rather than exposing a score() to
/// the session screen's check button.
class WritingRenderer extends StatefulWidget {
  final WritingPromptData data;
  final bool submitted;
  final ValueChanged<ScoreResult> onSubmit;

  const WritingRenderer({
    super.key,
    required this.data,
    required this.submitted,
    required this.onSubmit,
  });

  @override
  State<WritingRenderer> createState() => _WritingRendererState();
}

class _WritingRendererState extends State<WritingRenderer> {
  static const _minWords = 15;

  final _controller = TextEditingController();
  final Set<String> _ticked = {}; // ticked AFTER reveal (honest comparison)
  bool _revealed = false;

  int get _wordCount {
    final t = _controller.text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  bool get _canReveal => _wordCount >= _minWords;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(d.promptEn,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
        if (d.wordLimit != null) ...[
          const SizedBox(height: 6),
          Text(
            '${Bn.digits(d.wordLimit!.min ?? 0)}–${Bn.digits(d.wordLimit!.max ?? 0)} words',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          enabled: !widget.submitted && !_revealed,
          minLines: 5,
          maxLines: 12,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: Bn.yourAnswer,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 6),
        Text('${Bn.wordsWritten}: ${Bn.digits(_wordCount)} ${Bn.wordsUnit}',
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 16),

        if (!_revealed) ...[
          FilledButton.tonal(
            onPressed: _canReveal
                ? () => setState(() => _revealed = true)
                : null,
            child: const Text(Bn.showModelAnswer),
          ),
          if (!_canReveal) ...[
            const SizedBox(height: 8),
            Text(Bn.minWordsHint,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black45)),
          ],
        ] else ...[
          _ModelAnswer(text: d.modelAnswerEn),
          const SizedBox(height: 20),
          Text(Bn.compareAndTick,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final item in d.rubricChecklist)
            CheckboxListTile(
              value: _ticked.contains(item.id),
              onChanged: widget.submitted
                  ? null
                  : (v) => setState(() {
                        if (v == true) {
                          _ticked.add(item.id);
                        } else {
                          _ticked.remove(item.id);
                        }
                      }),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title:
                  Text(item.criterionBn, style: const TextStyle(fontSize: 15)),
            ),
          const SizedBox(height: 8),
          _ScoreBar(
            met: _ticked.length,
            total: d.rubricChecklist.length,
          ),
          const SizedBox(height: 16),
          if (!widget.submitted)
            FilledButton(
              onPressed: () => widget.onSubmit(ScoreResult.selfCheck),
              child: const Text(Bn.doneSelfCheck),
            ),
        ],
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final int met;
  final int total;
  const _ScoreBar({required this.met, required this.total});

  @override
  Widget build(BuildContext context) {
    final frac = total == 0 ? 0.0 : met / total;
    final color = frac >= 0.8
        ? AppTheme.correct
        : (frac >= 0.5 ? AppTheme.accent : AppTheme.incorrect);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Bn.youMet,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            Text('${Bn.digits(met)} / ${Bn.digits(total)}',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 8,
            backgroundColor: Colors.black12,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ModelAnswer extends StatelessWidget {
  final String text;
  const _ModelAnswer({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('নমুনা উত্তর',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}
