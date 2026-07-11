import 'package:flutter/material.dart';

import '../../engine/routing/focus_areas.dart';
import '../../l10n/strings_bn.dart';
import '../../theme/app_theme.dart';

/// The auto-surfaced weak-topics list. Each row says, in marks language, how the
/// student is doing and offers a one-tap jump into practising that topic.
class FocusAreaList extends StatelessWidget {
  final List<FocusArea> areas;
  final void Function(FocusArea area) onPractice;

  /// How many to show (home shows a few; the diagnostic result can show more).
  final int max;

  const FocusAreaList({
    super.key,
    required this.areas,
    required this.onPractice,
    this.max = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (areas.isEmpty) return const SizedBox.shrink();
    final shown = areas.take(max).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          Bn.focusAreasTitle,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        for (final area in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FocusAreaTile(area: area, onTap: () => onPractice(area)),
          ),
      ],
    );
  }
}

class _FocusAreaTile extends StatelessWidget {
  final FocusArea area;
  final VoidCallback onTap;
  const _FocusAreaTile({required this.area, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.incorrect.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.incorrect.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area.labelEn,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Bn.youdScore} ${Bn.digits(area.scoreOutOfTen)}/${Bn.digits(10)}'
                    '${area.weight > 0 ? '  •  ${Bn.digits(area.weight.round())} ${Bn.worthMarks}' : ''}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill, color: AppTheme.accent, size: 32),
          ],
        ),
      ),
    );
  }
}
