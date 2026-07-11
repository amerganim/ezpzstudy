import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../l10n/strings_bn.dart';
import '../../theme/app_theme.dart';
import '../session/session_screen.dart';
import 'diagnostic_result_screen.dart';

/// Intro to the HSC Readiness Check. Framed as exam readiness — never as a test
/// of "lower class" material.
class DiagnosticIntroScreen extends StatelessWidget {
  const DiagnosticIntroScreen({super.key});

  Future<void> _start(BuildContext context) async {
    final services = AppServices.of(context);
    final set = await services.questions.diagnosticSet();
    if (set.isEmpty || !context.mounted) return;
    await services.progress.startSession();
    if (!context.mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SessionScreen(
          topic: '__diagnostic__',
          titleOverride: Bn.readinessCheckTitle,
          questions: set,
          onFinish: (ctx, correct, total) async {
            await services.progress.markDiagnosticDone();
            if (!ctx.mounted) return;
            Navigator.of(ctx).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const DiagnosticResultScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Bn.readinessCheckTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text('🎯', style: TextStyle(fontSize: 64), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              const Text(
                Bn.readinessCheckTitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    Bn.readinessCheckIntro,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => _start(context),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
                child: const Text(Bn.startReadinessCheck),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
