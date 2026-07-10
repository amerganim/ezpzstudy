import '../../data/models/question_data.dart';
import 'levenshtein.dart';

/// Outcome of scoring one answer.
enum ScoreVerdict {
  correct,
  incorrect,

  /// Writing tasks are not auto-scored: the student reveals a model answer and
  /// a rubric checklist, then self-scores. The engine returns this so the UI
  /// knows to show the self-check flow instead of a right/wrong result.
  selfCheck,
}

class ScoreResult {
  final ScoreVerdict verdict;

  /// The canonical correct answer(s), for the "here's the right answer" panel
  /// shown after a wrong attempt.
  final List<String> correctAnswers;

  const ScoreResult(this.verdict, {this.correctAnswers = const []});

  bool get isCorrect => verdict == ScoreVerdict.correct;

  static const ScoreResult selfCheck = ScoreResult(ScoreVerdict.selfCheck);
}

/// Pure-Dart, no-network scoring for every auto-gradable question type.
///
/// Strategies, per the master plan:
///  - exact match: MCQ, matching, rearranging, word-bank fill-in
///  - fuzzy match (Levenshtein <= tolerance): open fill-in
///  - accepted-variants list: grammar transformations (also fuzzy per variant)
///  - self-check: writing tasks
class ScoringEngine {
  const ScoringEngine();

  /// Normalizes a free-text answer for comparison: trims, collapses internal
  /// whitespace, and (unless case-sensitive) lowercases.
  static String normalize(String input, {bool caseSensitive = false}) {
    var s = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (!caseSensitive) s = s.toLowerCase();
    return s;
  }

  // ---- MCQ -----------------------------------------------------------------

  ScoreResult scoreMcq(McqData data, String selectedKey) {
    final correct = selectedKey == data.correctOption;
    return ScoreResult(
      correct ? ScoreVerdict.correct : ScoreVerdict.incorrect,
      correctAnswers: [_mcqAnswerText(data)],
    );
  }

  String _mcqAnswerText(McqData data) {
    final opt = data.options.firstWhere(
      (o) => o.key == data.correctOption,
      orElse: () => McqOption(key: data.correctOption, textEn: ''),
    );
    return '${opt.key}. ${opt.textEn}';
  }

  // ---- Open fill-in (fuzzy) ------------------------------------------------

  ScoreResult scoreFillInOpen(FillInOpenData data, String answer) {
    final correct = _matchesAnyVariant(
      answer,
      data.acceptedAnswers,
      data.fuzzyTolerance,
      data.caseSensitive,
    );
    return ScoreResult(
      correct ? ScoreVerdict.correct : ScoreVerdict.incorrect,
      correctAnswers: data.acceptedAnswers,
    );
  }

  // ---- Word-bank fill-in (exact against a closed bank) ---------------------
  //
  // [answers] maps blank_id -> the word the student placed there.
  ScoreResult scoreFillInWordBank(
      FillInWordBankData data, Map<String, String> answers) {
    var allCorrect = true;
    for (final blank in data.blanks) {
      final given = answers[blank.blankId] ?? '';
      if (normalize(given) != normalize(blank.correctAnswer)) {
        allCorrect = false;
        break;
      }
    }
    return ScoreResult(
      allCorrect ? ScoreVerdict.correct : ScoreVerdict.incorrect,
      correctAnswers: data.blanks.map((b) => b.correctAnswer).toList(),
    );
  }

  // ---- Grammar transformation (accepted variants, fuzzy per variant) -------

  ScoreResult scoreGrammarTransformation(
      GrammarTransformationData data, String answer) {
    final correct = _matchesAnyVariant(
      answer,
      data.acceptedAnswers,
      data.fuzzyTolerance,
      data.caseSensitive,
    );
    return ScoreResult(
      correct ? ScoreVerdict.correct : ScoreVerdict.incorrect,
      correctAnswers: data.acceptedAnswers,
    );
  }

  // ---- Matching (exact set of pairs) ---------------------------------------
  //
  // [pairs] maps left_id -> right_id chosen by the student.
  ScoreResult scoreMatching(MatchingData data, Map<String, String> pairs) {
    var allCorrect = pairs.length == data.correctPairs.length;
    if (allCorrect) {
      for (final pair in data.correctPairs) {
        if (pairs[pair.leftId] != pair.rightId) {
          allCorrect = false;
          break;
        }
      }
    }
    return ScoreResult(
      allCorrect ? ScoreVerdict.correct : ScoreVerdict.incorrect,
      correctAnswers: data.correctPairs
          .map((p) => '${_matchText(data.leftItems, p.leftId)} → '
              '${_matchText(data.rightItems, p.rightId)}')
          .toList(),
    );
  }

  String _matchText(List<MatchItem> items, String id) => items
      .firstWhere((i) => i.id == id,
          orElse: () => MatchItem(id: id, textEn: ''))
      .textEn;

  // ---- Rearranging (exact sequence) ----------------------------------------

  ScoreResult scoreRearranging(RearrangingData data, List<String> orderedIds) {
    var correct = orderedIds.length == data.correctOrder.length;
    if (correct) {
      for (var i = 0; i < data.correctOrder.length; i++) {
        if (orderedIds[i] != data.correctOrder[i]) {
          correct = false;
          break;
        }
      }
    }
    final answerText = data.correctOrder
        .map((id) => data.units
            .firstWhere((u) => u.id == id,
                orElse: () => RearrangeUnit(id: id, textEn: ''))
            .textEn)
        .join(' ');
    return ScoreResult(
      correct ? ScoreVerdict.correct : ScoreVerdict.incorrect,
      correctAnswers: [answerText],
    );
  }

  // ---- Shared fuzzy-variant matcher ----------------------------------------

  bool _matchesAnyVariant(
    String answer,
    List<String> acceptedAnswers,
    int tolerance,
    bool caseSensitive,
  ) {
    final normAnswer = normalize(answer, caseSensitive: caseSensitive);
    if (normAnswer.isEmpty) return false;
    for (final variant in acceptedAnswers) {
      final normVariant = normalize(variant, caseSensitive: caseSensitive);
      if (normAnswer == normVariant) return true;
      if (tolerance > 0 && levenshtein(normAnswer, normVariant) <= tolerance) {
        return true;
      }
    }
    return false;
  }
}
