import 'package:flutter_test/flutter_test.dart';
import 'package:ezpzstudy/data/models/question_data.dart';
import 'package:ezpzstudy/engine/scoring/scoring_engine.dart';
import 'package:ezpzstudy/engine/scoring/levenshtein.dart';

void main() {
  const engine = ScoringEngine();

  group('levenshtein', () {
    test('identical strings have distance 0', () {
      expect(levenshtein('finished', 'finished'), 0);
    });
    test('single typo has distance 1', () {
      expect(levenshtein('finished', 'finisheed'), 1);
      expect(levenshtein('were', 'were '.trim()), 0);
    });
    test('handles empty strings', () {
      expect(levenshtein('', 'abc'), 3);
      expect(levenshtein('abc', ''), 3);
    });
  });

  group('MCQ', () {
    final data = const McqData(
      questionEn: 'She ___ to school.',
      options: [
        McqOption(key: 'A', textEn: 'go'),
        McqOption(key: 'B', textEn: 'goes'),
      ],
      correctOption: 'B',
    );
    test('correct key scores correct', () {
      expect(engine.scoreMcq(data, 'B').isCorrect, isTrue);
    });
    test('wrong key scores incorrect and surfaces the answer', () {
      final r = engine.scoreMcq(data, 'A');
      expect(r.isCorrect, isFalse);
      expect(r.correctAnswers.single, 'B. goes');
    });
  });

  group('fill-in-open (fuzzy)', () {
    final data = const FillInOpenData(
      sentenceEn: 'She has ___ her work.',
      acceptedAnswers: ['finished'],
      fuzzyTolerance: 1,
      caseSensitive: false,
    );
    test('exact match is correct', () {
      expect(engine.scoreFillInOpen(data, 'finished').isCorrect, isTrue);
    });
    test('single typo within tolerance is forgiven', () {
      expect(engine.scoreFillInOpen(data, 'finishd').isCorrect, isTrue);
    });
    test('case and surrounding whitespace ignored', () {
      expect(engine.scoreFillInOpen(data, '  FINISHED  ').isCorrect, isTrue);
    });
    test('too far off is incorrect', () {
      expect(engine.scoreFillInOpen(data, 'completed').isCorrect, isFalse);
    });
    test('empty answer is never correct', () {
      expect(engine.scoreFillInOpen(data, '   ').isCorrect, isFalse);
    });
    test('tolerance 0 requires exact', () {
      final strict = const FillInOpenData(
        sentenceEn: 'If I ___ you',
        acceptedAnswers: ['were'],
        fuzzyTolerance: 0,
        caseSensitive: false,
      );
      expect(engine.scoreFillInOpen(strict, 'were').isCorrect, isTrue);
      expect(engine.scoreFillInOpen(strict, 'wore').isCorrect, isFalse);
    });
  });

  group('grammar transformation (accepted variants)', () {
    final data = const GrammarTransformationData(
      transformationType: 'voice',
      originalSentenceEn: 'The teacher teaches the students.',
      acceptedAnswers: [
        'The students are taught by the teacher.',
        'The students are taught by the teacher',
      ],
      fuzzyTolerance: 2,
      caseSensitive: false,
    );
    test('accepts a listed variant', () {
      expect(
        engine
            .scoreGrammarTransformation(
                data, 'The students are taught by the teacher.')
            .isCorrect,
        isTrue,
      );
    });
    test('forgives a small typo within tolerance', () {
      expect(
        engine
            .scoreGrammarTransformation(
                data, 'The students are taught by the teachar.')
            .isCorrect,
        isTrue,
      );
    });
    test('rejects a wrong transformation', () {
      expect(
        engine
            .scoreGrammarTransformation(data, 'The teacher is taught.')
            .isCorrect,
        isFalse,
      );
    });
  });

  group('word-bank fill-in', () {
    final data = const FillInWordBankData(
      sentenceEn: 'He {{1}} to the market.',
      wordBank: ['went', 'goes', 'go'],
      blanks: [Blank(blankId: '1', correctAnswer: 'went')],
    );
    test('correct placement scores correct', () {
      expect(engine.scoreFillInWordBank(data, {'1': 'went'}).isCorrect, isTrue);
    });
    test('wrong placement scores incorrect', () {
      expect(engine.scoreFillInWordBank(data, {'1': 'goes'}).isCorrect, isFalse);
    });
  });

  group('matching', () {
    final data = const MatchingData(
      leftItems: [MatchItem(id: 'L1', textEn: 'Tense'), MatchItem(id: 'L2', textEn: 'Voice')],
      rightItems: [
        MatchItem(id: 'R1', textEn: 'Grammar of time'),
        MatchItem(id: 'R2', textEn: 'Active/passive'),
      ],
      correctPairs: [
        MatchPair(leftId: 'L1', rightId: 'R1'),
        MatchPair(leftId: 'L2', rightId: 'R2'),
      ],
    );
    test('all pairs right is correct', () {
      expect(
        engine.scoreMatching(data, {'L1': 'R1', 'L2': 'R2'}).isCorrect,
        isTrue,
      );
    });
    test('any pair wrong is incorrect', () {
      expect(
        engine.scoreMatching(data, {'L1': 'R2', 'L2': 'R1'}).isCorrect,
        isFalse,
      );
    });
  });

  group('rearranging', () {
    final data = const RearrangingData(
      unitType: 'word',
      units: [
        RearrangeUnit(id: 'U1', textEn: 'I'),
        RearrangeUnit(id: 'U2', textEn: 'am'),
        RearrangeUnit(id: 'U3', textEn: 'happy'),
      ],
      correctOrder: ['U1', 'U2', 'U3'],
    );
    test('correct order is correct', () {
      expect(engine.scoreRearranging(data, ['U1', 'U2', 'U3']).isCorrect, isTrue);
    });
    test('wrong order is incorrect', () {
      expect(engine.scoreRearranging(data, ['U2', 'U1', 'U3']).isCorrect, isFalse);
    });
  });
}
