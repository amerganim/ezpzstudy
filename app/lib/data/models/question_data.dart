import 'question.dart';

/// Type-specific payload for a [Question]. A sealed hierarchy so the renderer
/// and scoring engine can pattern-match exhaustively over every question type.
sealed class QuestionData {
  const QuestionData();

  factory QuestionData.fromJson(QuestionType type, Map<String, dynamic> json) {
    switch (type) {
      case QuestionType.flashcard:
        return FlashcardData.fromJson(json);
      case QuestionType.mcq:
        return McqData.fromJson(json);
      case QuestionType.fillInWordBank:
        return FillInWordBankData.fromJson(json);
      case QuestionType.fillInOpen:
        return FillInOpenData.fromJson(json);
      case QuestionType.matching:
        return MatchingData.fromJson(json);
      case QuestionType.rearranging:
        return RearrangingData.fromJson(json);
      case QuestionType.grammarTransformation:
        return GrammarTransformationData.fromJson(json);
      case QuestionType.comprehensionSet:
        return ComprehensionSetData.fromJson(json);
      case QuestionType.writingPrompt:
        return WritingPromptData.fromJson(json);
    }
  }
}

class FlashcardData extends QuestionData {
  final String frontEn;
  final String backBn;
  final String? exampleSentenceEn;
  final String? partOfSpeech;
  final String? synonym;
  final String? antonym;

  const FlashcardData({
    required this.frontEn,
    required this.backBn,
    this.exampleSentenceEn,
    this.partOfSpeech,
    this.synonym,
    this.antonym,
  });

  factory FlashcardData.fromJson(Map<String, dynamic> json) => FlashcardData(
        frontEn: json['front_en'] as String,
        backBn: json['back_bn'] as String,
        exampleSentenceEn: json['example_sentence_en'] as String?,
        partOfSpeech: json['part_of_speech'] as String?,
        synonym: json['synonym'] as String?,
        antonym: json['antonym'] as String?,
      );
}

class McqOption {
  final String key; // "A".."D"
  final String textEn;
  const McqOption({required this.key, required this.textEn});

  factory McqOption.fromJson(Map<String, dynamic> json) => McqOption(
        key: json['key'] as String,
        textEn: json['text_en'] as String,
      );
}

class McqData extends QuestionData {
  final String questionEn;
  final List<McqOption> options;
  final String correctOption; // key

  const McqData({
    required this.questionEn,
    required this.options,
    required this.correctOption,
  });

  factory McqData.fromJson(Map<String, dynamic> json) => McqData(
        questionEn: json['question_en'] as String,
        options: (json['options'] as List<dynamic>)
            .map((e) => McqOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        correctOption: json['correct_option'] as String,
      );
}

class Blank {
  final String blankId;
  final String correctAnswer;
  const Blank({required this.blankId, required this.correctAnswer});

  factory Blank.fromJson(Map<String, dynamic> json) => Blank(
        blankId: json['blank_id'] as String,
        correctAnswer: json['correct_answer'] as String,
      );
}

class FillInWordBankData extends QuestionData {
  final String sentenceEn; // contains {{1}}, {{2}} markers
  final List<String> wordBank;
  final List<Blank> blanks;

  const FillInWordBankData({
    required this.sentenceEn,
    required this.wordBank,
    required this.blanks,
  });

  factory FillInWordBankData.fromJson(Map<String, dynamic> json) =>
      FillInWordBankData(
        sentenceEn: json['sentence_en'] as String,
        wordBank:
            (json['word_bank'] as List<dynamic>).map((e) => e as String).toList(),
        blanks: (json['blanks'] as List<dynamic>)
            .map((e) => Blank.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class FillInOpenData extends QuestionData {
  final String sentenceEn;
  final List<String> acceptedAnswers;
  final int fuzzyTolerance;
  final bool caseSensitive;

  const FillInOpenData({
    required this.sentenceEn,
    required this.acceptedAnswers,
    required this.fuzzyTolerance,
    required this.caseSensitive,
  });

  factory FillInOpenData.fromJson(Map<String, dynamic> json) => FillInOpenData(
        sentenceEn: json['sentence_en'] as String,
        acceptedAnswers: (json['accepted_answers'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        fuzzyTolerance: (json['fuzzy_tolerance'] as num?)?.toInt() ?? 1,
        caseSensitive: json['case_sensitive'] as bool? ?? false,
      );
}

class MatchItem {
  final String id;
  final String textEn;
  const MatchItem({required this.id, required this.textEn});

  factory MatchItem.fromJson(Map<String, dynamic> json) => MatchItem(
        id: json['id'] as String,
        textEn: json['text_en'] as String,
      );
}

class MatchPair {
  final String leftId;
  final String rightId;
  const MatchPair({required this.leftId, required this.rightId});

  factory MatchPair.fromJson(Map<String, dynamic> json) => MatchPair(
        leftId: json['left_id'] as String,
        rightId: json['right_id'] as String,
      );
}

class MatchingData extends QuestionData {
  final List<MatchItem> leftItems;
  final List<MatchItem> rightItems;
  final List<MatchPair> correctPairs;

  const MatchingData({
    required this.leftItems,
    required this.rightItems,
    required this.correctPairs,
  });

  factory MatchingData.fromJson(Map<String, dynamic> json) => MatchingData(
        leftItems: (json['left_items'] as List<dynamic>)
            .map((e) => MatchItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        rightItems: (json['right_items'] as List<dynamic>)
            .map((e) => MatchItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        correctPairs: (json['correct_pairs'] as List<dynamic>)
            .map((e) => MatchPair.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RearrangeUnit {
  final String id;
  final String textEn;
  const RearrangeUnit({required this.id, required this.textEn});

  factory RearrangeUnit.fromJson(Map<String, dynamic> json) => RearrangeUnit(
        id: json['id'] as String,
        textEn: json['text_en'] as String,
      );
}

class RearrangingData extends QuestionData {
  final String unitType; // "word" | "sentence"
  final List<RearrangeUnit> units;
  final List<String> correctOrder; // list of unit ids

  const RearrangingData({
    required this.unitType,
    required this.units,
    required this.correctOrder,
  });

  factory RearrangingData.fromJson(Map<String, dynamic> json) => RearrangingData(
        unitType: json['unit_type'] as String,
        units: (json['units'] as List<dynamic>)
            .map((e) => RearrangeUnit.fromJson(e as Map<String, dynamic>))
            .toList(),
        correctOrder: (json['correct_order'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
      );
}

class GrammarTransformationData extends QuestionData {
  final String transformationType;
  final String originalSentenceEn;
  final List<String> acceptedAnswers;
  final int fuzzyTolerance;
  final bool caseSensitive;

  const GrammarTransformationData({
    required this.transformationType,
    required this.originalSentenceEn,
    required this.acceptedAnswers,
    required this.fuzzyTolerance,
    required this.caseSensitive,
  });

  factory GrammarTransformationData.fromJson(Map<String, dynamic> json) =>
      GrammarTransformationData(
        transformationType: json['transformation_type'] as String,
        originalSentenceEn: json['original_sentence_en'] as String,
        acceptedAnswers: (json['accepted_answers'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        fuzzyTolerance: (json['fuzzy_tolerance'] as num?)?.toInt() ?? 2,
        caseSensitive: json['case_sensitive'] as bool? ?? false,
      );
}

/// A sub-question nested inside a comprehension set. Reuses the same data
/// classes but carries only a reduced envelope (id/type/topic/instruction).
class SubQuestion {
  final String id;
  final QuestionType type;
  final String? topic;
  final String? subtopic;
  final String? instructionBn;
  final String? explanationBn;
  final QuestionData data;

  const SubQuestion({
    required this.id,
    required this.type,
    this.topic,
    this.subtopic,
    this.instructionBn,
    this.explanationBn,
    required this.data,
  });

  factory SubQuestion.fromJson(Map<String, dynamic> json) {
    final type = QuestionType.fromJson(json['type'] as String);
    return SubQuestion(
      id: json['id'] as String,
      type: type,
      topic: json['topic'] as String?,
      subtopic: json['subtopic'] as String?,
      instructionBn: json['instruction_bn'] as String?,
      explanationBn: json['explanation_bn'] as String?,
      data: QuestionData.fromJson(type, json['data'] as Map<String, dynamic>),
    );
  }
}

class ComprehensionSetData extends QuestionData {
  final String passageEn;
  final String passageSource; // "original" | "adapted"
  final List<SubQuestion> subQuestions;

  const ComprehensionSetData({
    required this.passageEn,
    required this.passageSource,
    required this.subQuestions,
  });

  factory ComprehensionSetData.fromJson(Map<String, dynamic> json) =>
      ComprehensionSetData(
        passageEn: json['passage_en'] as String,
        passageSource: json['passage_source'] as String,
        subQuestions: (json['sub_questions'] as List<dynamic>)
            .map((e) => SubQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RubricItem {
  final String id;
  final String criterionBn;
  const RubricItem({required this.id, required this.criterionBn});

  factory RubricItem.fromJson(Map<String, dynamic> json) => RubricItem(
        id: json['id'] as String,
        criterionBn: json['criterion_bn'] as String,
      );
}

class WordLimit {
  final int? min;
  final int? max;
  const WordLimit({this.min, this.max});

  factory WordLimit.fromJson(Map<String, dynamic> json) => WordLimit(
        min: (json['min'] as num?)?.toInt(),
        max: (json['max'] as num?)?.toInt(),
      );
}

class WritingPromptData extends QuestionData {
  final String writingType;
  final String promptEn;
  final WordLimit? wordLimit;
  final String modelAnswerEn;
  final List<RubricItem> rubricChecklist;

  const WritingPromptData({
    required this.writingType,
    required this.promptEn,
    this.wordLimit,
    required this.modelAnswerEn,
    required this.rubricChecklist,
  });

  factory WritingPromptData.fromJson(Map<String, dynamic> json) =>
      WritingPromptData(
        writingType: json['writing_type'] as String,
        promptEn: json['prompt_en'] as String,
        wordLimit: json['word_limit'] == null
            ? null
            : WordLimit.fromJson(json['word_limit'] as Map<String, dynamic>),
        modelAnswerEn: json['model_answer_en'] as String,
        rubricChecklist: (json['rubric_checklist'] as List<dynamic>)
            .map((e) => RubricItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
