import 'package:flutter/material.dart';

import '../../l10n/strings_bn.dart';
import '../../l10n/topic_labels.dart';
import '../../theme/app_theme.dart';

/// End-of-session summary: score framed as marks, encouraging tone, and a clear
/// path back to more practice.
class SessionSummaryScreen extends StatelessWidget {
  final String topic;
  final int correct;
  final int total;
  const SessionSummaryScreen({
    super.key,
    required this.topic,
    required this.correct,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (correct / total * 100).round();
    final resultIcon = pct >= 80
        ? Icons.celebration_rounded
        : pct >= 50
            ? Icons.thumb_up_rounded
            : Icons.trending_up_rounded;
    final resultColor =
        pct >= 50 ? AppTheme.accent : const Color(0xFFF9A825);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(resultIcon, size: 64, color: resultColor),
              const SizedBox(height: 12),
              const Text(Bn.sessionComplete,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(TopicLabels.of(topic),
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Text(Bn.youScored,
                          style: const TextStyle(
                              fontSize: 15, color: Colors.black54)),
                      const SizedBox(height: 6),
                      Text(
                        '${Bn.digits(correct)} / ${Bn.digits(total)}',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentDark,
                        ),
                      ),
                      Text('${Bn.digits(pct)}%',
                          style: const TextStyle(
                              fontSize: 18, color: Colors.black54)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(Bn.keepGoing,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16)),
              const Spacer(),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text(Bn.backToHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
