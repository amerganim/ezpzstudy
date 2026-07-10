import 'package:flutter/material.dart';

import '../../../data/models/question_data.dart';
import '../../../engine/scoring/scoring_engine.dart';
import '../../../theme/app_theme.dart';
import 'answer_renderer.dart';

class McqRenderer extends StatefulWidget {
  final McqData data;
  final RendererArgs args;
  const McqRenderer({super.key, required this.data, required this.args});

  @override
  State<McqRenderer> createState() => McqRendererState();
}

class McqRendererState extends State<McqRenderer> implements AutoGraded {
  String? _selected;

  @override
  bool get canSubmit => _selected != null;

  @override
  ScoreResult score() => widget.args.engine.scoreMcq(widget.data, _selected!);

  @override
  Widget build(BuildContext context) {
    final answered = widget.args.answered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.data.questionEn,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        for (final opt in widget.data.options)
          _OptionTile(
            option: opt,
            selected: _selected == opt.key,
            answered: answered,
            isCorrectOption: opt.key == widget.data.correctOption,
            onTap: answered
                ? null
                : () {
                    setState(() => _selected = opt.key);
                    widget.args.onChanged();
                  },
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final McqOption option;
  final bool selected;
  final bool answered;
  final bool isCorrectOption;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.option,
    required this.selected,
    required this.answered,
    required this.isCorrectOption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color border = Colors.black12;
    Color? fill;
    if (answered) {
      if (isCorrectOption) {
        border = AppTheme.correct;
        fill = AppTheme.correct.withValues(alpha: 0.10);
      } else if (selected) {
        border = AppTheme.incorrect;
        fill = AppTheme.incorrect.withValues(alpha: 0.10);
      }
    } else if (selected) {
      border = AppTheme.accent;
      fill = AppTheme.accent.withValues(alpha: 0.08);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border, width: 1.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: selected ? AppTheme.accent : Colors.black12,
                child: Text(option.key,
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(option.textEn,
                    style: const TextStyle(fontSize: 17)),
              ),
              if (answered && isCorrectOption)
                const Icon(Icons.check_circle, color: AppTheme.correct),
              if (answered && selected && !isCorrectOption)
                const Icon(Icons.cancel, color: AppTheme.incorrect),
            ],
          ),
        ),
      ),
    );
  }
}
