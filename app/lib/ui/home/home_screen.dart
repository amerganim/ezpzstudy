import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/progress_repository.dart';
import '../../l10n/strings_bn.dart';
import '../../theme/app_theme.dart';
import '../flashcards/flashcard_screen.dart';
import '../topics/topic_list_screen.dart';

/// Home: streak front and center, then the two ways in — practice by topic and
/// vocabulary flashcards. Maximum 3 taps from here to answering a question.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<ProgressSnapshot> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = AppServices.of(context).progress.snapshot();
  }

  void _refresh() {
    setState(() {
      _snapshot = AppServices.of(context).progress.snapshot();
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<ProgressSnapshot>(
          future: _snapshot,
          builder: (context, snap) {
            final data = snap.data;
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
                Text(
                  Bn.homeGreeting,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                _StreakCard(streakDays: data?.streakDays ?? 0),
                const SizedBox(height: 16),
                _PredictedScoreCard(snapshot: data),
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
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: ' ${Bn.streakDays}',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : const Text(
                      Bn.noStreakYet,
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictedScoreCard extends StatelessWidget {
  final ProgressSnapshot? snapshot;
  const _PredictedScoreCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    if (s == null || s.totalAttempts == 0) {
      return const SizedBox.shrink();
    }
    final pct = (s.totalCorrect / s.totalAttempts * 100).round();
    return Card(
      color: AppTheme.accent.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(Bn.scoreLabel,
                      style: TextStyle(fontSize: 15, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    '${Bn.digits(pct)}%',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentDark,
                    ),
                  ),
                ],
              ),
            ),
            Text('${Bn.digits(s.totalCorrect)}/${Bn.digits(s.totalAttempts)}',
                style: const TextStyle(fontSize: 18, color: Colors.black54)),
          ],
        ),
      ),
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
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
