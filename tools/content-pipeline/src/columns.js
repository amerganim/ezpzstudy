"use strict";

// Single source of truth for the spreadsheet layout, shared by the template
// generator, the row reader, and the row-to-question mapper. Keeping this in
// one place is what lets the template and the parser never drift apart.

const SHARED_COLUMNS = [
  "id",
  "paper",
  "topic",
  "subtopic",
  "difficulty",
  "marks_weight",
  "tags",
  "instruction_bn",
  "explanation_bn",
  "review_status",
  "author",
];

const TYPE_COLUMNS = {
  flashcard: ["front_en", "back_bn", "example_sentence_en", "part_of_speech", "synonym", "antonym"],
  mcq: ["question_en", "option_a", "option_b", "option_c", "option_d", "correct_option"],
  fill_in_word_bank: ["sentence_en", "word_bank", "answer_1", "answer_2", "answer_3"],
  fill_in_open: ["sentence_en", "accepted_answers", "fuzzy_tolerance", "case_sensitive"],
  matching: [
    "left_1", "left_2", "left_3", "left_4", "left_5", "left_6",
    "right_1", "right_2", "right_3", "right_4", "right_5", "right_6",
  ],
  rearranging: [
    "unit_type",
    "unit_1", "unit_2", "unit_3", "unit_4", "unit_5", "unit_6", "unit_7", "unit_8",
  ],
  grammar_transformation: [
    "transformation_type", "original_sentence_en", "accepted_answers",
    "fuzzy_tolerance", "case_sensitive",
  ],
  writing_prompt: [
    "writing_type", "prompt_en", "word_limit_min", "word_limit_max", "model_answer_en",
    "rubric_1_bn", "rubric_2_bn", "rubric_3_bn", "rubric_4_bn",
    "rubric_5_bn", "rubric_6_bn", "rubric_7_bn", "rubric_8_bn",
  ],
};

// Extra optional columns, present only on tabs whose rows can be pulled into a
// comprehension_set's sub_questions instead of standing alone as top-level questions.
const COMPREHENSION_LINK_COLUMNS = ["passage_id", "sub_order"];
const COMPREHENSION_LINKABLE_TABS = ["mcq", "fill_in_word_bank", "fill_in_open", "matching"];

const COMPREHENSION_PASSAGE_COLUMNS = [
  "passage_id", "paper", "topic", "subtopic", "difficulty", "marks_weight",
  "tags", "instruction_bn", "explanation_bn", "review_status", "author",
  "passage_en", "passage_source",
];

const DROPDOWNS = {
  paper: ["1st", "2nd"],
  difficulty: ["easy", "medium", "hard"],
  review_status: ["draft", "reviewed", "published"],
  correct_option: ["A", "B", "C", "D"],
  case_sensitive: ["Y", "N"],
  part_of_speech: [
    "noun", "verb", "adjective", "adverb", "preposition", "conjunction", "pronoun", "interjection",
  ],
  unit_type: ["word", "sentence"],
  transformation_type: [
    "voice", "narration", "tag_question", "connector", "preposition",
    "punctuation", "degree", "sentence_combination", "other",
  ],
  writing_type: [
    "paragraph", "essay", "application", "letter_formal", "letter_informal",
    "email", "cv", "dialogue", "report",
  ],
  passage_source: ["original", "adapted"],
};

const TABS = Object.keys(TYPE_COLUMNS);

function tabColumns(tabName) {
  const cols = [...SHARED_COLUMNS, ...TYPE_COLUMNS[tabName]];
  if (COMPREHENSION_LINKABLE_TABS.includes(tabName)) {
    cols.push(...COMPREHENSION_LINK_COLUMNS);
  }
  return cols;
}

module.exports = {
  SHARED_COLUMNS,
  TYPE_COLUMNS,
  COMPREHENSION_LINK_COLUMNS,
  COMPREHENSION_LINKABLE_TABS,
  COMPREHENSION_PASSAGE_COLUMNS,
  DROPDOWNS,
  TABS,
  tabColumns,
};
