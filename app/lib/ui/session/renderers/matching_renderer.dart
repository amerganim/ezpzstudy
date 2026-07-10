import 'package:flutter/material.dart';

import '../../../data/models/question_data.dart';
import '../../../engine/scoring/scoring_engine.dart';
import '../../../theme/app_theme.dart';
import 'answer_renderer.dart';

/// Matching: each left item gets a dropdown of the (shuffled) right items.
/// Exact set match. Right-side display order is shuffled once per render so the
/// answer key's positional order isn't a giveaway.
class MatchingRenderer extends StatefulWidget {
  final MatchingData data;
  final RendererArgs args;
  const MatchingRenderer({super.key, required this.data, required this.args});

  @override
  State<MatchingRenderer> createState() => MatchingRendererState();
}

class MatchingRendererState extends State<MatchingRenderer>
    implements AutoGraded {
  final Map<String, String> _pairs = {}; // leftId -> rightId
  late final List<MatchItem> _shuffledRight;

  @override
  void initState() {
    super.initState();
    _shuffledRight = List.of(widget.data.rightItems)..shuffle();
  }

  @override
  bool get canSubmit =>
      widget.data.leftItems.every((l) => _pairs.containsKey(l.id));

  @override
  ScoreResult score() => widget.args.engine.scoreMatching(widget.data, _pairs);

  String _correctRightFor(String leftId) => widget.data.correctPairs
      .firstWhere((p) => p.leftId == leftId)
      .rightId;

  @override
  Widget build(BuildContext context) {
    final answered = widget.args.answered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final left in widget.data.leftItems)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MatchRow(
              leftText: left.textEn,
              value: _pairs[left.id],
              rightItems: _shuffledRight,
              answered: answered,
              correctRightId: _correctRightFor(left.id),
              onChanged: answered
                  ? null
                  : (v) {
                      setState(() => _pairs[left.id] = v!);
                      widget.args.onChanged();
                    },
            ),
          ),
      ],
    );
  }
}

class _MatchRow extends StatelessWidget {
  final String leftText;
  final String? value;
  final List<MatchItem> rightItems;
  final bool answered;
  final String correctRightId;
  final ValueChanged<String?>? onChanged;

  const _MatchRow({
    required this.leftText,
    required this.value,
    required this.rightItems,
    required this.answered,
    required this.correctRightId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Color border = Colors.black26;
    if (answered && value != null) {
      border = value == correctRightId ? AppTheme.correct : AppTheme.incorrect;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Text(leftText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const Icon(Icons.arrow_right_alt, color: Colors.black38),
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: border, width: 1.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: const Text('...'),
                items: [
                  for (final r in rightItems)
                    DropdownMenuItem(
                      value: r.id,
                      child: Text(r.textEn,
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
