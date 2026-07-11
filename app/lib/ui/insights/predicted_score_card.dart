import 'package:flutter/material.dart';

import '../../engine/scoring/predicted_score.dart';
import '../../l10n/strings_bn.dart';
import '../../theme/app_theme.dart';

/// The killer feature, visualized: the weighted Predicted Board Score, framed in
/// the language of marks. Rises as accuracy improves across weighted topics.
class PredictedScoreCard extends StatelessWidget {
  final PredictedScore score;
  const PredictedScoreCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    if (!score.available) return const SizedBox.shrink();
    final pct = score.percent;
    final coverage = (score.coverage * 100).round();
    return Card(
      color: AppTheme.accent.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(Bn.predictedBoardScore,
                style: TextStyle(fontSize: 15, color: Colors.black54)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${Bn.digits(pct)}%',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 10,
                backgroundColor: Colors.black12,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${Bn.basedOnSoFar} (${Bn.digits(coverage)}%)',
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}
