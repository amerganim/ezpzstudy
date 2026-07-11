import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../engine/insights_service.dart';
import '../../l10n/strings_bn.dart';
import '../../theme/app_theme.dart';
import '../insights/focus_area_list.dart';
import '../insights/predicted_score_card.dart';
import '../session/session_screen.dart';

/// Shown right after the Readiness Check: the student's first Predicted Board
/// Score and their top Focus Areas — turning a diagnostic into a plan.
class DiagnosticResultScreen extends StatefulWidget {
  const DiagnosticResultScreen({super.key});

  @override
  State<DiagnosticResultScreen> createState() => _DiagnosticResultScreenState();
}

class _DiagnosticResultScreenState extends State<DiagnosticResultScreen> {
  late Future<Insights> _insights;

  @override
  void initState() {
    super.initState();
    _insights = AppServices.of(context).insights.load();
  }

  Future<void> _practice(String topic) async {
    final services = AppServices.of(context);
    final set = await services.questions.practiceSet(topic);
    if (set.isEmpty || !mounted) return;
    await services.progress.startSession();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionScreen(topic: topic, questions: set),
      ),
    );
    if (mounted) {
      setState(() {
        _insights = AppServices.of(context).insights.load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Bn.readinessCheckDone),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Insights>(
        future: _insights,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final insights = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('✅',
                  style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              PredictedScoreCard(score: insights.predictedScore),
              const SizedBox(height: 20),
              FocusAreaList(
                areas: insights.focusAreas,
                max: 5,
                onPractice: (a) => _practice(a.topicId),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style:
                    FilledButton.styleFrom(backgroundColor: AppTheme.accent),
                child: const Text(Bn.seeYourPlan),
              ),
            ],
          );
        },
      ),
    );
  }
}
