import 'package:flutter/material.dart';

import '../../../data/models/question_data.dart';
import '../../../engine/scoring/scoring_engine.dart';
import '../../../theme/app_theme.dart';
import 'answer_renderer.dart';

/// Rearranging: units start shuffled and the student drags them into order.
/// Exact sequence match against the answer key.
class RearrangingRenderer extends StatefulWidget {
  final RearrangingData data;
  final RendererArgs args;
  const RearrangingRenderer({super.key, required this.data, required this.args});

  @override
  State<RearrangingRenderer> createState() => RearrangingRendererState();
}

class RearrangingRendererState extends State<RearrangingRenderer>
    implements AutoGraded {
  late List<RearrangeUnit> _order;

  @override
  void initState() {
    super.initState();
    _order = List.of(widget.data.units)..shuffle();
    // Guard against an accidental already-correct shuffle.
    if (_isCorrectOrder() && _order.length > 1) {
      final first = _order.removeAt(0);
      _order.add(first);
    }
  }

  bool _isCorrectOrder() {
    for (var i = 0; i < _order.length; i++) {
      if (_order[i].id != widget.data.correctOrder[i]) return false;
    }
    return true;
  }

  @override
  bool get canSubmit => true; // the current arrangement is always a valid answer

  @override
  ScoreResult score() => widget.args.engine
      .scoreRearranging(widget.data, _order.map((u) => u.id).toList());

  @override
  Widget build(BuildContext context) {
    final answered = widget.args.answered;
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: !answered,
      onReorderItem: answered
          ? (_, _) {}
          : (oldIndex, newIndex) {
              setState(() {
                final item = _order.removeAt(oldIndex);
                _order.insert(newIndex, item);
              });
              widget.args.onChanged();
            },
      children: [
        for (var i = 0; i < _order.length; i++)
          _UnitTile(
            key: ValueKey(_order[i].id),
            index: i,
            unit: _order[i],
            answered: answered,
            isInRightPlace:
                answered && _order[i].id == widget.data.correctOrder[i],
          ),
      ],
    );
  }
}

class _UnitTile extends StatelessWidget {
  final int index;
  final RearrangeUnit unit;
  final bool answered;
  final bool isInRightPlace;

  const _UnitTile({
    super.key,
    required this.index,
    required this.unit,
    required this.answered,
    required this.isInRightPlace,
  });

  @override
  Widget build(BuildContext context) {
    Color border = AppTheme.accent.withValues(alpha: 0.4);
    if (answered) {
      border = isInRightPlace ? AppTheme.correct : AppTheme.incorrect;
    }
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceTint,
          border: Border.all(color: border, width: 1.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text('${index + 1}.',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.black45)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(unit.textEn, style: const TextStyle(fontSize: 17)),
            ),
            if (!answered)
              const Icon(Icons.drag_handle, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
