"use strict";

const BANGLA_RANGE = /[ঀ-৿]/;

function err(source, column, message) {
  return { sheet: source.sheet, row: source.row, column, message };
}

function warn(source, column, message) {
  return { sheet: source.sheet, row: source.row, column, message };
}

function collectValidTopicIds(topicMap) {
  const ids = new Set();
  const sections = [
    "paper_1st", "paper_1st_writing", "paper_2nd_grammar",
    "paper_2nd_writing", "cross_cutting",
  ];
  for (const section of sections) {
    const topics = topicMap[section] && topicMap[section].topics;
    if (Array.isArray(topics)) {
      for (const t of topics) ids.add(t.id);
    }
  }
  if (Array.isArray(topicMap.remedial_topics)) {
    for (const t of topicMap.remedial_topics) ids.add(t.id);
  }
  return ids;
}

function checkBnField(question, source, fieldPath, value, warnings) {
  if (!value) return;
  if (!BANGLA_RANGE.test(value)) {
    warnings.push(
      warn(source, fieldPath, `"${fieldPath}" does not appear to contain Bangla characters -- check for wrong-column paste`)
    );
  }
}

/**
 * entries: [{ question, source: {sheet,row} }]
 * topicMap: parsed topic-map.yaml
 */
function validateSemantics(entries, topicMap) {
  const errors = [];
  const warnings = [];
  const validTopics = collectValidTopicIds(topicMap);
  const seenIds = new Map(); // id -> source

  for (const { question, source } of entries) {
    // 1. global id uniqueness
    if (seenIds.has(question.id)) {
      const first = seenIds.get(question.id);
      errors.push(
        err(source, "id", `duplicate id "${question.id}" (first seen at ${first.sheet} row ${first.row})`)
      );
    } else {
      seenIds.set(question.id, source);
    }

    // 2. topic must exist in topic-map.yaml
    if (question.topic && !validTopics.has(question.topic)) {
      errors.push(err(source, "topic", `topic "${question.topic}" is not defined in topic-map.yaml`));
    }

    // 3. type-specific semantic checks
    if (question.type === "mcq") {
      const keys = new Set((question.data.options || []).map((o) => o.key));
      if (question.data.correct_option && !keys.has(question.data.correct_option)) {
        errors.push(
          err(source, "correct_option", `correct_option "${question.data.correct_option}" does not match any option key (${[...keys].join(", ")})`)
        );
      }
    }

    if (question.type === "fill_in_word_bank") {
      const sentence = question.data.sentence_en || "";
      const markers = [...sentence.matchAll(/\{\{(\d+)\}\}/g)].map((m) => m[1]);
      const blankIds = new Set((question.data.blanks || []).map((b) => b.blank_id));
      for (const marker of markers) {
        if (!blankIds.has(marker)) {
          errors.push(err(source, "sentence_en", `blank {{${marker}}} in sentence_en has no answer_${marker} value`));
        }
      }
      const bank = (question.data.word_bank || []).map((w) => w.toLowerCase());
      for (const blank of question.data.blanks || []) {
        if (!bank.includes(String(blank.correct_answer).toLowerCase())) {
          warnings.push(
            warn(source, "word_bank", `correct_answer "${blank.correct_answer}" for blank ${blank.blank_id} does not appear in word_bank`)
          );
        }
      }
    }

    // 4. comprehension sub-questions: recurse topic checks + Bangla checks
    if (question.type === "comprehension_set") {
      for (const sub of question.data.sub_questions || []) {
        if (sub.topic && !validTopics.has(sub.topic)) {
          errors.push(err(source, "sub_questions.topic", `topic "${sub.topic}" is not defined in topic-map.yaml`));
        }
      }
    }

    // 5. soft Bangla checks
    checkBnField(question, source, "instruction_bn", question.instruction_bn, warnings);
    checkBnField(question, source, "explanation_bn", question.explanation_bn, warnings);
    if (question.type === "flashcard") {
      checkBnField(question, source, "back_bn", question.data.back_bn, warnings);
    }
    if (question.type === "writing_prompt") {
      for (const item of question.data.rubric_checklist || []) {
        checkBnField(question, source, `rubric.${item.id}`, item.criterion_bn, warnings);
      }
    }
  }

  return { errors, warnings };
}

module.exports = { validateSemantics, collectValidTopicIds, BANGLA_RANGE };
