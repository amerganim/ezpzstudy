import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/models/question.dart';
import '../../data/models/topic_map.dart';
import '../../data/question_repository.dart';
import '../../l10n/strings_bn.dart';
import '../../l10n/topic_labels.dart';
import '../../theme/app_theme.dart';
import '../session/session_screen.dart';
import 'level_sheet.dart';

/// Lists practiceable topics, split into two sections: Basics (Pass-first
/// foundations) and HSC Practice (full syllabus). The split is driven by each
/// topic's `track` in the topic map, so a weak student sees a clear, unashamed
/// starting point. Tapping a topic starts a 10-question session.
class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  late Future<_GroupedTopics> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _handleRefresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  Future<_GroupedTopics> _load() async {
    final services = AppServices.of(context);
    final summaries = await services.questions.practiceTopics();
    final map = await services.topicMap.load();
    final basics = <TopicSummary>[];
    final hsc = <TopicSummary>[];
    for (final s in summaries) {
      final info = map.byId(s.topic);
      (info?.isBasics ?? false ? basics : hsc).add(s);
    }
    return _GroupedTopics(basics: basics, hsc: hsc, map: map);
  }

  /// Opens the level chooser; the picked level (or "all") starts the session.
  Future<void> _chooseLevel(String topic, String label) async {
    final counts = await AppServices.of(context).questions.difficultyCounts(topic);
    if (!mounted) return;
    final choice = await showModalBottomSheet<LevelChoice>(
      context: context,
      showDragHandle: true,
      // Size to content and respect the nav-bar inset, so the "all levels"
      // action button is never pushed below the fold / behind the nav bar.
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => LevelSheet(topicLabel: label, counts: counts),
    );
    if (choice == null || !mounted) return; // dismissed
    await _startSession(topic, choice.difficulty);
  }

  Future<void> _startSession(String topic, Difficulty? difficulty) async {
    final services = AppServices.of(context);
    final set = await services.questions
        .practiceSet(topic, difficulty: difficulty);
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
      body: FutureBuilder<_GroupedTopics>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          if (data.basics.isEmpty && data.hsc.isEmpty) {
            return const Center(child: Text(Bn.nothingHere));
          }
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
            children: [
              if (data.basics.isNotEmpty) ...[
                const _SectionHeader(
                  icon: Icons.foundation_rounded,
                  title: Bn.basicsSectionTitle,
                  subtitle: Bn.basicsSectionSub,
                ),
                for (final t in data.basics)
                  _TopicCard(
                    summary: t,
                    label: _label(data.map, t.topic),
                    onTap: () => _chooseLevel(t.topic, _label(data.map, t.topic)),
                  ),
              ],
              if (data.hsc.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _SectionHeader(
                  icon: Icons.school_rounded,
                  title: Bn.hscSectionTitle,
                  subtitle: Bn.hscSectionSub,
                ),
                for (final t in data.hsc)
                  _TopicCard(
                    summary: t,
                    label: _label(data.map, t.topic),
                    marks: data.map.byId(t.topic)?.weight,
                    onTap: () => _chooseLevel(t.topic, _label(data.map, t.topic)),
                  ),
              ],
            ],
            ),
          );
        },
      ),
    );
  }

  String _label(TopicMap map, String topicId) {
    final bn = map.byId(topicId)?.labelBn;
    return (bn != null && bn.isNotEmpty) ? bn : TopicLabels.of(topicId);
  }
}

class _GroupedTopics {
  final List<TopicSummary> basics;
  final List<TopicSummary> hsc;
  final TopicMap map;
  const _GroupedTopics({
    required this.basics,
    required this.hsc,
    required this.map,
  });
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 26, color: AppTheme.accentDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentDark)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final TopicSummary summary;
  final String label;
  final num? marks;
  final VoidCallback onTap;
  const _TopicCard({
    required this.summary,
    required this.label,
    required this.onTap,
    this.marks,
  });

  @override
  Widget build(BuildContext context) {
    final showMarks = marks != null && marks! > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(label,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          subtitle: Text(
            '${Bn.digits(summary.questionCount)} ${Bn.questionsAvailable}'
            '${showMarks ? '  •  ${Bn.digits(marks!.round())} ${Bn.worthMarks}' : ''}',
            style: const TextStyle(fontSize: 14),
          ),
          trailing:
              const Icon(Icons.chevron_right, color: AppTheme.accent, size: 28),
          onTap: onTap,
        ),
      ),
    );
  }
}
