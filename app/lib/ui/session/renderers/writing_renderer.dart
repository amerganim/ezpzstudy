import 'package:flutter/material.dart';

import '../../../data/models/question_data.dart';
import '../../../engine/scoring/scoring_engine.dart';
import '../../../l10n/strings_bn.dart';
import '../../../theme/app_theme.dart';

/// Writing prompt: not auto-scored. The student writes (on paper or in the
/// field), then must tick the rubric checklist before the model answer is
/// revealed — nudging honest self-assessment, per the pilot's expected failure
/// mode where students mark themselves correct without checking.
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
  final _controller = TextEditingController();
  final Set<String> _ticked = {};
  bool _revealed = false;

  bool get _allTicked =>
      widget.data.rubricChecklist.every((r) => _ticked.contains(r.id));

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
          enabled: !widget.submitted,
          minLines: 4,
          maxLines: 10,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: Bn.yourAnswer,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        Text(Bn.selfCheckTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
            title: Text(item.criterionBn, style: const TextStyle(fontSize: 15)),
          ),
        const SizedBox(height: 12),
        if (!_revealed)
          FilledButton.tonal(
            onPressed: _allTicked ? () => setState(() => _revealed = true) : null,
            child: const Text(Bn.showModelAnswer),
          )
        else ...[
          _ModelAnswer(text: d.modelAnswerEn),
          const SizedBox(height: 16),
          if (!widget.submitted)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        widget.onSubmit(ScoreResult.selfCheck),
                    child: const Text(Bn.iNeedPractice),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        widget.onSubmit(ScoreResult.selfCheck),
                    child: const Text(Bn.iGotItRight),
                  ),
                ),
              ],
            ),
        ],
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
