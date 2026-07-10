import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/question_repository.dart';
import '../../l10n/strings_bn.dart';
import '../../l10n/topic_labels.dart';
import '../../theme/app_theme.dart';
import '../session/session_screen.dart';

/// Lists practiceable topics. Tapping one starts a 10-question session.
class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  late Future<List<TopicSummary>> _topics;

  @override
  void initState() {
    super.initState();
    _topics = AppServices.of(context).questions.practiceTopics();
  }

  Future<void> _startSession(String topic) async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Bn.chooseTopic)),
      body: FutureBuilder<List<TopicSummary>>(
        future: _topics,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final topics = snap.data!;
          if (topics.isEmpty) {
            return const Center(child: Text(Bn.nothingHere));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: topics.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final t = topics[i];
              return Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(
                    TopicLabels.of(t.topic),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${Bn.digits(t.questionCount)} ${Bn.questionsAvailable}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppTheme.accent, size: 28),
                  onTap: () => _startSession(t.topic),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
