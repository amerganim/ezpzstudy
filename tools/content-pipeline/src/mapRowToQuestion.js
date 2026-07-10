"use strict";

const PAPER_CODE = { "1st": "p1", "2nd": "p2" };

function err(row, column, message) {
  return { sheet: row.__sheet, row: row.__row, column, message };
}

function splitList(value, separator) {
  if (!value) return [];
  return String(value)
    .split(separator)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}

function parseBool(value, fieldName, row, errors) {
  if (value === "" || value === undefined) return undefined;
  const v = String(value).trim().toUpperCase();
  if (v === "Y") return true;
  if (v === "N") return false;
  errors.push(err(row, fieldName, `expected Y or N, got "${value}"`));
  return undefined;
}

function parseIntOrUndefined(value, fieldName, row, errors) {
  if (value === "" || value === undefined) return undefined;
  const n = Number(value);
  if (!Number.isInteger(n)) {
    errors.push(err(row, fieldName, `expected an integer, got "${value}"`));
    return undefined;
  }
  return n;
}

function buildEnvelope(row, type) {
  const errors = [];
  const paper = row.paper;
  const localId = row.id;
  const paperCode = PAPER_CODE[paper] || "p?";
  const envelope = {
    id: `${paperCode}.${type}.${localId}`,
    type,
    paper,
    topic: row.topic,
    difficulty: row.difficulty,
    marks_weight: Number(row.marks_weight),
    tags: splitList(row.tags, ","),
    instruction_bn: row.instruction_bn,
    explanation_bn: row.explanation_bn,
    review_status: row.review_status || "draft",
    author: row.author,
  };
  if (row.subtopic) envelope.subtopic = row.subtopic;
  if (Number.isNaN(envelope.marks_weight)) {
    errors.push(err(row, "marks_weight", `expected a number, got "${row.marks_weight}"`));
  }
  return { envelope, errors };
}

function mapFlashcard(row) {
  const { envelope, errors } = buildEnvelope(row, "flashcard");
  const data = {
    front_en: row.front_en,
    back_bn: row.back_bn,
  };
  if (row.example_sentence_en) data.example_sentence_en = row.example_sentence_en;
  if (row.part_of_speech) data.part_of_speech = row.part_of_speech;
  if (row.synonym) data.synonym = row.synonym;
  if (row.antonym) data.antonym = row.antonym;
  return { question: { ...envelope, data }, errors };
}

function mapMcq(row) {
  const { envelope, errors } = buildEnvelope(row, "mcq");
  const optionKeys = ["A", "B", "C", "D"];
  const options = [];
  for (const key of optionKeys) {
    const cell = row[`option_${key.toLowerCase()}`];
    if (cell) options.push({ key, text_en: cell });
  }
  if (options.length < 2) {
    errors.push(err(row, "option_a..option_d", "at least 2 options are required"));
  }
  const data = { question_en: row.question_en, options, correct_option: row.correct_option };
  return { question: { ...envelope, data }, errors };
}

function mapFillInWordBank(row) {
  const { envelope, errors } = buildEnvelope(row, "fill_in_word_bank");
  const blanks = [];
  for (let i = 1; i <= 3; i++) {
    const cell = row[`answer_${i}`];
    if (cell) blanks.push({ blank_id: String(i), correct_answer: cell });
  }
  if (blanks.length === 0) {
    errors.push(err(row, "answer_1..answer_3", "at least one answer_N column must be filled"));
  }
  const data = {
    sentence_en: row.sentence_en,
    word_bank: splitList(row.word_bank, ","),
    blanks,
  };
  return { question: { ...envelope, data }, errors };
}

function mapFillInOpen(row) {
  const { envelope, errors } = buildEnvelope(row, "fill_in_open");
  const data = {
    sentence_en: row.sentence_en,
    accepted_answers: splitList(row.accepted_answers, "|"),
  };
  const fuzzy = parseIntOrUndefined(row.fuzzy_tolerance, "fuzzy_tolerance", row, errors);
  data.fuzzy_tolerance = fuzzy === undefined ? 1 : fuzzy;
  const caseSensitive = parseBool(row.case_sensitive, "case_sensitive", row, errors);
  data.case_sensitive = caseSensitive === undefined ? false : caseSensitive;
  return { question: { ...envelope, data }, errors };
}

function mapMatching(row) {
  const { envelope, errors } = buildEnvelope(row, "matching");
  const left_items = [];
  const right_items = [];
  const correct_pairs = [];
  for (let i = 1; i <= 6; i++) {
    const leftCell = row[`left_${i}`];
    const rightCell = row[`right_${i}`];
    const leftFilled = !!leftCell;
    const rightFilled = !!rightCell;
    if (!leftFilled && !rightFilled) continue;
    if (leftFilled !== rightFilled) {
      errors.push(err(row, `left_${i}/right_${i}`, "left and right columns must be filled in pairs"));
      continue;
    }
    const leftId = `L${i}`;
    const rightId = `R${i}`;
    left_items.push({ id: leftId, text_en: leftCell });
    right_items.push({ id: rightId, text_en: rightCell });
    correct_pairs.push({ left_id: leftId, right_id: rightId });
  }
  if (correct_pairs.length < 2) {
    errors.push(err(row, "left_1..right_6", "at least 2 matching pairs are required"));
  }
  const data = { left_items, right_items, correct_pairs };
  return { question: { ...envelope, data }, errors };
}

function mapRearranging(row) {
  const { envelope, errors } = buildEnvelope(row, "rearranging");
  const units = [];
  const correct_order = [];
  for (let i = 1; i <= 8; i++) {
    const cell = row[`unit_${i}`];
    if (!cell) continue;
    const id = `U${i}`;
    units.push({ id, text_en: cell });
    correct_order.push(id);
  }
  if (units.length < 2) {
    errors.push(err(row, "unit_1..unit_8", "at least 2 units are required"));
  }
  const data = { unit_type: row.unit_type, units, correct_order };
  return { question: { ...envelope, data }, errors };
}

function mapGrammarTransformation(row) {
  const { envelope, errors } = buildEnvelope(row, "grammar_transformation");
  const data = {
    transformation_type: row.transformation_type,
    original_sentence_en: row.original_sentence_en,
    accepted_answers: splitList(row.accepted_answers, "|"),
  };
  const fuzzy = parseIntOrUndefined(row.fuzzy_tolerance, "fuzzy_tolerance", row, errors);
  data.fuzzy_tolerance = fuzzy === undefined ? 2 : fuzzy;
  const caseSensitive = parseBool(row.case_sensitive, "case_sensitive", row, errors);
  data.case_sensitive = caseSensitive === undefined ? false : caseSensitive;
  return { question: { ...envelope, data }, errors };
}

function mapWritingPrompt(row) {
  const { envelope, errors } = buildEnvelope(row, "writing_prompt");
  const rubric_checklist = [];
  for (let i = 1; i <= 8; i++) {
    const cell = row[`rubric_${i}_bn`];
    if (cell) rubric_checklist.push({ id: `r${i}`, criterion_bn: cell });
  }
  if (rubric_checklist.length === 0) {
    errors.push(err(row, "rubric_1_bn..rubric_8_bn", "at least one rubric item is required"));
  }
  const data = {
    writing_type: row.writing_type,
    prompt_en: row.prompt_en,
    model_answer_en: row.model_answer_en,
    rubric_checklist,
  };
  const min = parseIntOrUndefined(row.word_limit_min, "word_limit_min", row, errors);
  const max = parseIntOrUndefined(row.word_limit_max, "word_limit_max", row, errors);
  if (min !== undefined || max !== undefined) {
    data.word_limit = {};
    if (min !== undefined) data.word_limit.min = min;
    if (max !== undefined) data.word_limit.max = max;
  }
  return { question: { ...envelope, data }, errors };
}

// Reduced mapper for a comprehension sub-question row: same per-type `data` shape
// as the standalone mapper, but only id/topic/subtopic/instruction/explanation as
// envelope-lite fields (no paper/difficulty/marks_weight/author -- those are
// inherited from the parent comprehension_set).
function mapSubQuestion(tabName, row) {
  const fullMapperByType = {
    mcq: mapMcq,
    fill_in_word_bank: mapFillInWordBank,
    fill_in_open: mapFillInOpen,
    matching: mapMatching,
  };
  const mapper = fullMapperByType[tabName];
  const { question, errors } = mapper(row);
  const subQuestion = {
    id: row.id,
    type: tabName,
    data: question.data,
  };
  if (row.topic) subQuestion.topic = row.topic;
  if (row.subtopic) subQuestion.subtopic = row.subtopic;
  if (row.instruction_bn) subQuestion.instruction_bn = row.instruction_bn;
  if (row.explanation_bn) subQuestion.explanation_bn = row.explanation_bn;
  return { subQuestion, errors };
}

function mapComprehensionPassage(row) {
  const { envelope, errors } = buildEnvelope({ ...row, id: row.passage_id }, "comprehension_set");
  const data = {
    passage_en: row.passage_en,
    passage_source: row.passage_source,
    sub_questions: [], // filled in by buildPack.js once linkable rows are gathered
  };
  return { question: { ...envelope, data }, errors };
}

const MAPPERS = {
  flashcard: mapFlashcard,
  mcq: mapMcq,
  fill_in_word_bank: mapFillInWordBank,
  fill_in_open: mapFillInOpen,
  matching: mapMatching,
  rearranging: mapRearranging,
  grammar_transformation: mapGrammarTransformation,
  writing_prompt: mapWritingPrompt,
};

module.exports = {
  MAPPERS,
  mapComprehensionPassage,
  mapSubQuestion,
  err,
};
