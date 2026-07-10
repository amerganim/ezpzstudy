import 'question_data.dart';

/// The nine question types in the content pack. String values match the
/// `type` field in the JSON schema exactly.
enum QuestionType {
  flashcard,
  mcq,
  fillInWordBank,
  fillInOpen,
  matching,
  rearranging,
  grammarTransformation,
  comprehensionSet,
  writingPrompt;

  static QuestionType fromJson(String value) {
    switch (value) {
      case 'flashcard':
        return QuestionType.flashcard;
      case 'mcq':
        return QuestionType.mcq;
      case 'fill_in_word_bank':
        return QuestionType.fillInWordBank;
      case 'fill_in_open':
        return QuestionType.fillInOpen;
      case 'matching':
        return QuestionType.matching;
      case 'rearranging':
        return QuestionType.rearranging;
      case 'grammar_transformation':
        return QuestionType.grammarTransformation;
      case 'comprehension_set':
        return QuestionType.comprehensionSet;
      case 'writing_prompt':
        return QuestionType.writingPrompt;
      default:
        throw FormatException('Unknown question type: $value');
    }
  }
}

enum Difficulty {
  easy,
  medium,
  hard;

  static Difficulty fromJson(String value) => Difficulty.values.firstWhere(
        (d) => d.name == value,
        orElse: () => Difficulty.medium,
      );
}

/// A single question: the common envelope plus a type-specific [data] payload.
/// Mirrors content/schema/question-schema.json (envelope + nested `data`).
class Question {
  final String id;
  final QuestionType type;
  final String paper; // "1st" | "2nd"
  final String topic;
  final String? subtopic;
  final Difficulty difficulty;
  final num marksWeight;
  final List<String> tags;
  final String instructionBn;
  final String explanationBn;
  final String reviewStatus;
  final String author;
  final QuestionData data;

  const Question({
    required this.id,
    required this.type,
    required this.paper,
    required this.topic,
    this.subtopic,
    required this.difficulty,
    required this.marksWeight,
    required this.tags,
    required this.instructionBn,
    required this.explanationBn,
    required this.reviewStatus,
    required this.author,
    required this.data,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final type = QuestionType.fromJson(json['type'] as String);
    return Question(
      id: json['id'] as String,
      type: type,
      paper: json['paper'] as String,
      topic: json['topic'] as String,
      subtopic: json['subtopic'] as String?,
      difficulty: Difficulty.fromJson(json['difficulty'] as String),
      marksWeight: json['marks_weight'] as num,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      instructionBn: json['instruction_bn'] as String,
      explanationBn: json['explanation_bn'] as String,
      reviewStatus: json['review_status'] as String,
      author: json['author'] as String,
      data: QuestionData.fromJson(type, json['data'] as Map<String, dynamic>),
    );
  }
}
