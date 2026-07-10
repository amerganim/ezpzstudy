import 'package:flutter/foundation.dart';

import '../../data/models/question.dart';
import '../../data/progress_repository.dart';
import '../scoring/scoring_engine.dart';

/// Drives one practice session: a fixed set of questions, one at a time, with
/// instant per-question feedback, then a summary. Records each attempt as a
/// topic-progress aggregate.
class SessionController extends ChangeNotifier {
  final List<Question> questions;
  final ProgressRepository progress;

  int _currentIndex = 0;
  ScoreResult? _currentResult; // null until the current question is checked
  final List<bool> _outcomes = [];

  SessionController({required this.questions, required this.progress});

  int get currentIndex => _currentIndex;
  int get total => questions.length;
  Question get current => questions[_currentIndex];
  ScoreResult? get currentResult => _currentResult;
  bool get isAnswered => _currentResult != null;
  bool get isLastQuestion => _currentIndex == questions.length - 1;
  int get correctCount => _outcomes.where((c) => c).length;
  bool get isComplete => _outcomes.length == questions.length;

  /// Submit the scored result for the current question. Idempotent within a
  /// question — a second call before [next] is ignored.
  Future<void> submit(ScoreResult result) async {
    if (_currentResult != null) return;
    _currentResult = result;
    // Writing self-check questions don't count toward accuracy aggregates.
    if (result.verdict != ScoreVerdict.selfCheck) {
      _outcomes.add(result.isCorrect);
      await progress.recordAttempt(current.topic, result.isCorrect);
    } else {
      _outcomes.add(true); // completed, not graded
    }
    notifyListeners();
  }

  /// Advance to the next question. Returns false if the session is complete.
  bool next() {
    if (_currentIndex >= questions.length - 1) {
      notifyListeners();
      return false;
    }
    _currentIndex++;
    _currentResult = null;
    notifyListeners();
    return true;
  }
}
