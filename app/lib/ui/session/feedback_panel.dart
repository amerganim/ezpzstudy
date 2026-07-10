import 'package:flutter/material.dart';

import '../../engine/scoring/scoring_engine.dart';
import '../../l10n/strings_bn.dart';
import '../../theme/app_theme.dart';

/// Shown immediately after an answer is checked. On a wrong answer it always
/// shows the correct answer plus the one-line Bangla rule — never just "Wrong."
class FeedbackPanel extends StatelessWidget {
  final ScoreResult result;
  final String explanationBn;
  const FeedbackPanel(
      {super.key, required this.result, required this.explanationBn});

  @override
  Widget build(BuildContext context) {
    final correct = result.isCorrect;
    final color = correct ? AppTheme.correct : AppTheme.incorrect;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.check_circle : Icons.cancel, color: color),
              const SizedBox(width: 8),
              Text(
                correct ? Bn.correct : Bn.incorrect,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          if (!correct && result.correctAnswers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(Bn.correctAnswerIs,
                style: const TextStyle(
                    fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 2),
            for (final ans in result.correctAnswers)
              Text(ans,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
          ],
          if (explanationBn.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(explanationBn,
                style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
