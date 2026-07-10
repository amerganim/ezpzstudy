import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/flashcard_repository.dart';
import '../../data/models/question_data.dart';
import '../../engine/srs/sm2.dart';
import '../../l10n/strings_bn.dart';
import '../../theme/app_theme.dart';

/// Spaced-repetition flashcard review. One card at a time: recall, reveal,
/// self-grade. The SM-2 scheduler decides when each card returns.
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late Future<List<DueCard>> _queueFuture;
  List<DueCard>? _queue;
  int _index = 0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _queueFuture = AppServices.of(context).flashcards.dueQueue();
  }

  Future<void> _grade(RecallGrade grade) async {
    final card = _queue![_index];
    await AppServices.of(context).flashcards.grade(card, grade);
    setState(() {
      _index++;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Bn.vocabularyFlashcards)),
      body: FutureBuilder<List<DueCard>>(
        future: _queueFuture,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          _queue ??= snap.data!;
          final queue = _queue!;
          if (queue.isEmpty || _index >= queue.length) {
            return _DoneView(reviewed: _index);
          }
          return _CardView(
            card: queue[_index],
            revealed: _revealed,
            position: _index + 1,
            total: queue.length,
            onReveal: () => setState(() => _revealed = true),
            onGrade: _grade,
          );
        },
      ),
    );
  }
}

class _CardView extends StatelessWidget {
  final DueCard card;
  final bool revealed;
  final int position;
  final int total;
  final VoidCallback onReveal;
  final ValueChanged<RecallGrade> onGrade;

  const _CardView({
    required this.card,
    required this.revealed,
    required this.position,
    required this.total,
    required this.onReveal,
    required this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    final FlashcardData f = card.flashcard;
    return Column(
      children: [
        LinearProgressIndicator(
          value: position / total,
          backgroundColor: Colors.black12,
          color: AppTheme.accent,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(Bn.flashcardFront,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 16),
                Text(f.frontEn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.w800)),
                if (f.partOfSpeech != null) ...[
                  const SizedBox(height: 6),
                  Text('(${f.partOfSpeech})',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, color: Colors.black45)),
                ],
                const SizedBox(height: 24),
                if (revealed) _Back(f: f),
              ],
            ),
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: revealed
              ? Row(
                  children: [
                    Expanded(
                      child: _GradeButton(
                        label: Bn.recallAgain,
                        color: AppTheme.incorrect,
                        onTap: () => onGrade(RecallGrade.again),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GradeButton(
                        label: Bn.recallGood,
                        color: AppTheme.accent,
                        onTap: () => onGrade(RecallGrade.good),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GradeButton(
                        label: Bn.recallEasy,
                        color: AppTheme.correct,
                        onTap: () => onGrade(RecallGrade.easy),
                      ),
                    ),
                  ],
                )
              : FilledButton(
                  onPressed: onReveal,
                  child: const Text(Bn.showMeaning),
                ),
        ),
      ],
    );
  }
}

class _Back extends StatelessWidget {
  final FlashcardData f;
  const _Back({required this.f});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(f.backBn,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w700)),
          if (f.exampleSentenceEn != null) ...[
            const SizedBox(height: 14),
            Text(f.exampleSentenceEn!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87)),
          ],
          if (f.synonym != null || f.antonym != null) ...[
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                if (f.synonym != null)
                  Chip(label: Text('= ${f.synonym}')),
                if (f.antonym != null)
                  Chip(label: Text('≠ ${f.antonym}')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _GradeButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size.fromHeight(52),
        padding: EdgeInsets.zero,
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15)),
    );
  }
}

class _DoneView extends StatelessWidget {
  final int reviewed;
  const _DoneView({required this.reviewed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✅', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(Bn.noCardsDue,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(Bn.backToHome),
            ),
          ],
        ),
      ),
    );
  }
}
