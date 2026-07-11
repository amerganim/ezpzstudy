import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/progress_repository.dart';
import '../../engine/insights_service.dart';
import '../../l10n/strings_bn.dart';
import '../../theme/app_theme.dart';
import '../diagnostic/diagnostic_intro_screen.dart';
import '../flashcards/flashcard_screen.dart';
import '../insights/focus_area_list.dart';
import '../insights/predicted_score_card.dart';
import '../session/session_screen.dart';
import '../topics/topic_list_screen.dart';

/// Home: streak, the diagnostic CTA (or its results — predicted score + Focus
/// Areas), then the ways in — practice by topic, flashcards, and (once cleared)
/// the Challenge track. Maximum 3 taps from here to answering a question.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_HomeData> _load() async {
    final services = AppServices.of(context);
    final snapshot = await services.progress.snapshot();
    final insights = await services.insights.load();
    return _HomeData(snapshot: snapshot, insights: insights);
  }

  void _refresh() {
    setState(() {
      _data = _load();
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _refresh();
  }

  Future<void> _practiceTopic(String topic) async {
    final services = AppServices.of(context);
    final set = await services.questions.practiceSet(topic);
    if (set.isEmpty || !mounted) return;
    await services.progress.startSession();
    if (!mounted) return;
    await _open(SessionScreen(topic: topic, questions: set));
  }

  Future<void> _startChallenge() async {
    final services = AppServices.of(context);
    final set = await services.questions.challengeSet();
    if (set.isEmpty || !mounted) return;
    await services.progress.startSession();
    if (!mounted) return;
    await _open(SessionScreen(
      topic: '__challenge__',
      titleOverride: Bn.challengeTitle,
      questions: set,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_HomeData>(
          future: _data,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snap.data!;
            final insights = data.insights;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 8),
                Text(
                  Bn.appName,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(Bn.homeGreeting,
                    style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 20),
                _StreakCard(streakDays: data.snapshot.streakDays),
                const SizedBox(height: 16),

                // Before the diagnostic: a prominent CTA. After: the results.
                if (!insights.diagnosticDone)
                  _DiagnosticCta(
                      onTap: () => _open(const DiagnosticIntroScreen()))
                else ...[
                  PredictedScoreCard(score: insights.predictedScore),
                  const SizedBox(height: 16),
                  FocusAreaList(
                    areas: insights.focusAreas,
                    onPractice: (a) => _practiceTopic(a.topicId),
                  ),
                  if (insights.focusAreas.isNotEmpty)
                    const SizedBox(height: 16),
                  if (insights.allClear) ...[
                    _ChallengeCard(onTap: _startChallenge),
                    const SizedBox(height: 16),
                  ],
                ],

                _WeeklyCard(snapshot: data.snapshot),
                const SizedBox(height: 24),
                _BigActionButton(
                  icon: Icons.menu_book_rounded,
                  label: Bn.practiceByTopic,
                  onTap: () => _open(const TopicListScreen()),
                ),
                const SizedBox(height: 14),
                _BigActionButton(
                  icon: Icons.style_rounded,
                  label: Bn.vocabularyFlashcards,
                  filled: false,
                  onTap: () => _open(const FlashcardScreen()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeData {
  final ProgressSnapshot snapshot;
  final Insights insights;
  const _HomeData({required this.snapshot, required this.insights});
}

class _StreakCard extends StatelessWidget {
  final int streakDays;
  const _StreakCard({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final has = streakDays > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Text(has ? '🔥' : '✨', style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: has
                  ? RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black87),
                        children: [
                          TextSpan(
                            text: Bn.digits(streakDays),
                            style: const TextStyle(
                                fontSize: 30, fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: ' ${Bn.streakDays}',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : const Text(Bn.noStreakYet,
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticCta extends StatelessWidget {
  final VoidCallback onTap;
  const _DiagnosticCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Bn.takeReadinessCheck,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  SizedBox(height: 4),
                  Text(Bn.takeReadinessCheckSub,
                      style: TextStyle(fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ChallengeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accentDark, AppTheme.accent],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Bn.challengeUnlocked,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  SizedBox(height: 4),
                  Text(Bn.challengeSub,
                      style: TextStyle(fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  final ProgressSnapshot snapshot;
  const _WeeklyCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    if (snapshot.totalAttempts == 0) return const SizedBox.shrink();
    final acc = snapshot.totalAttempts == 0
        ? 0
        : (snapshot.totalCorrect / snapshot.totalAttempts * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(
                value: Bn.digits(snapshot.totalAttempts),
                label: Bn.questionsAnswered),
            _Stat(value: '${Bn.digits(acc)}%', label: Bn.scoreLabel),
            _Stat(
                value: Bn.digits(snapshot.totalSessions),
                label: Bn.thisWeek),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.accentDark)),
        const SizedBox(height: 2),
        SizedBox(
          width: 90,
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ),
      ],
    );
  }
}

class _BigActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _BigActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 26),
        const SizedBox(width: 12),
        Text(label,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
    if (filled) {
      return FilledButton(onPressed: onTap, child: child);
    }
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        foregroundColor: AppTheme.accentDark,
        side: const BorderSide(color: AppTheme.accent, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: child,
    );
  }
}
