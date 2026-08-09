import 'package:flutter/material.dart';

import '../../data/models/question.dart';
import '../../l10n/strings_bn.dart';
import '../../theme/app_theme.dart';

/// A chosen practice level. `difficulty == null` means "all levels mixed".
class LevelChoice {
  final Difficulty? difficulty;
  const LevelChoice(this.difficulty);
}

/// Bottom sheet that lets the student pick a difficulty level within a topic —
/// so a weak student can start easy and build up. Levels with no questions are
/// shown disabled. Returns a [LevelChoice] via Navigator.pop, or null if
/// dismissed.
class LevelSheet extends StatelessWidget {
  final String topicLabel;
  final Map<Difficulty, int> counts;

  const LevelSheet({
    super.key,
    required this.topicLabel,
    required this.counts,
  });

  int get _total =>
      (counts[Difficulty.easy] ?? 0) +
      (counts[Difficulty.medium] ?? 0) +
      (counts[Difficulty.hard] ?? 0);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // Scrollable so the sheet never overflows on short screens or topics with
      // long labels.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(topicLabel,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            const Text(Bn.chooseLevel,
                style: TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 16),
            _LevelTile(
              color: const Color(0xFF43A047), // green
              label: Bn.levelEasy,
              hint: Bn.levelEasyHint,
              count: counts[Difficulty.easy] ?? 0,
              onTap: () => Navigator.of(context)
                  .pop(const LevelChoice(Difficulty.easy)),
            ),
            _LevelTile(
              color: const Color(0xFFF9A825), // amber
              label: Bn.levelMedium,
              count: counts[Difficulty.medium] ?? 0,
              onTap: () => Navigator.of(context)
                  .pop(const LevelChoice(Difficulty.medium)),
            ),
            _LevelTile(
              color: const Color(0xFFE53935), // red
              label: Bn.levelHard,
              count: counts[Difficulty.hard] ?? 0,
              onTap: () => Navigator.of(context)
                  .pop(const LevelChoice(Difficulty.hard)),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _total == 0
                  ? null
                  : () => Navigator.of(context).pop(const LevelChoice(null)),
              child: Text('${Bn.levelAll} (${Bn.digits(_total)})'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final Color color;
  final String label;
  final String? hint;
  final int count;
  final VoidCallback onTap;

  const _LevelTile({
    required this.color,
    required this.label,
    required this.count,
    required this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = count > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 18, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      Text(
                        enabled
                            ? '${Bn.digits(count)} ${Bn.questionsAvailable}'
                                '${hint != null ? '  •  $hint' : ''}'
                            : Bn.noQuestionsAtLevel,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  const Icon(Icons.chevron_right, color: AppTheme.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
