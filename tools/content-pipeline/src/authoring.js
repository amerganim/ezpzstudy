"use strict";

// JSON authoring path.
//
// Hand-editing xlsx doesn't scale to thousands of items. Authors (and bulk
// content work) instead write compact JSON grouped by topic; this module
// expands each file into full, schema-valid question objects that go through
// the SAME schema + semantic validation as the xlsx path, then into the same
// pack. One authoring file = one topic:
//
//   {
//     "topic": "p2_preposition",
//     "paper": "2nd",                 // "1st" | "2nd" | "both"
//     "instruction_bn": "...",        // default instruction for every item
//     "author": "ezpz-content",
//     "difficulty": "easy",           // default; per-item override allowed
//     "items": [ { "type": "...", ...compact fields..., "rule_bn": "..." } ]
//   }
//
// Compact item shapes (per type) are documented in content/authoring/README.md.

const fs = require("fs");
const path = require("path");

const PAPER_DECK = { "1st": "p1", "2nd": "p2", both: "b" };

function pad(n) {
  return String(n).padStart(3, "0");
}

function letter(i) {
  return String.fromCharCode(65 + i); // 0 -> A
}

function need(item, field) {
  if (item[field] === undefined || item[field] === null) {
    throw new Error(`missing "${field}"`);
  }
  return item[field];
}

/** Default fuzzy tolerance: exact for single words, forgiving for phrases. */
function defaultTolerance(answers) {
  const maxWords = Math.max(...answers.map((a) => String(a).trim().split(/\s+/).length));
  return maxWords <= 1 ? 0 : 2;
}

// ---- per-type expanders: compact item -> schema `data` ----------------------

const DATA_BUILDERS = {
  flashcard(item) {
    return {
      front_en: need(item, "front"),
      back_bn: need(item, "back_bn"),
      ...(item.example ? { example_sentence_en: item.example } : {}),
      ...(item.pos ? { part_of_speech: item.pos } : {}),
      ...(item.syn ? { synonym: item.syn } : {}),
      ...(item.ant ? { antonym: item.ant } : {}),
    };
  },

  mcq(item) {
    const opts = need(item, "opts");
    const options = opts.map((t, i) => ({ key: letter(i), text_en: String(t) }));
    let correct = need(item, "correct");
    if (typeof correct === "number") correct = letter(correct);
    return { question_en: need(item, "q"), options, correct_option: correct };
  },

  fill_in_open(item) {
    const answers = need(item, "a").map(String);
    return {
      sentence_en: need(item, "q"),
      accepted_answers: answers,
      fuzzy_tolerance: item.fuzzy !== undefined ? item.fuzzy : defaultTolerance(answers),
      case_sensitive: item.case === true,
    };
  },

  fill_in_word_bank(item) {
    const bank = need(item, "bank").map(String);
    const ans = need(item, "ans").map(String); // positional: ans[i] -> {{i+1}}
    return {
      sentence_en: need(item, "q"),
      word_bank: bank,
      blanks: ans.map((a, i) => ({ blank_id: String(i + 1), correct_answer: a })),
    };
  },

  matching(item) {
    const left = need(item, "left").map((t, i) => ({ id: `L${i + 1}`, text_en: String(t) }));
    const right = need(item, "right").map((t, i) => ({ id: `R${i + 1}`, text_en: String(t) }));
    const pairs = need(item, "pairs").map(([li, ri]) => ({
      left_id: `L${li + 1}`,
      right_id: `R${ri + 1}`,
    }));
    return { left_items: left, right_items: right, correct_pairs: pairs };
  },

  rearranging(item) {
    let unitType, parts;
    if (item.sentences) {
      unitType = "sentence";
      parts = item.sentences.map(String);
    } else {
      unitType = item.unit === "sentence" ? "sentence" : "word";
      parts = String(need(item, "answer")).trim().split(/\s+/);
    }
    const units = parts.map((t, i) => ({ id: `U${i + 1}`, text_en: t }));
    return { unit_type: unitType, units, correct_order: units.map((u) => u.id) };
  },

  grammar_transformation(item) {
    const answers = need(item, "a").map(String);
    return {
      transformation_type: item.transform || "transformation",
      original_sentence_en: need(item, "original"),
      accepted_answers: answers,
      fuzzy_tolerance: item.fuzzy !== undefined ? item.fuzzy : 2,
      case_sensitive: item.case === true,
    };
  },

  writing_prompt(item) {
    const rubric = need(item, "rubric").map((c, i) => ({
      id: `R${i + 1}`,
      criterion_bn: String(c),
    }));
    return {
      writing_type: need(item, "writing_type"),
      prompt_en: need(item, "prompt"),
      ...(item.words ? { word_limit: { min: item.words[0], max: item.words[1] } } : {}),
      model_answer_en: need(item, "model"),
      rubric_checklist: rubric,
    };
  },

  comprehension_set(item) {
    const allowed = ["mcq", "fill_in_word_bank", "fill_in_open", "matching"];
    const subs = need(item, "subs").map((s, i) => {
      const subType = need(s, "type");
      const subBuilder = DATA_BUILDERS[subType];
      if (!subBuilder || !allowed.includes(subType)) {
        throw new Error(`sub-question type "${subType}" not allowed in comprehension_set`);
      }
      return {
        id: `s${i + 1}`,
        type: subType,
        ...(s.rule_bn ? { explanation_bn: s.rule_bn } : {}),
        data: subBuilder(s),
      };
    });
    return {
      passage_en: need(item, "passage"),
      passage_source: item.source || "original",
      sub_questions: subs,
    };
  },
};

function expandItem(item, ctx) {
  const type = need(item, "type");
  const builder = DATA_BUILDERS[type];
  if (!builder) throw new Error(`unknown type "${type}"`);

  const data = builder(item);

  // explanation_bn is a hard requirement (never just "Wrong"). Flashcards fall
  // back to the Bangla meaning; writing prompts (self-checked, no wrong-answer
  // feedback) fall back to a standard note.
  const explanation =
    item.rule_bn ||
    (type === "flashcard" ? data.back_bn : null) ||
    (type === "writing_prompt"
      ? "নিজে লেখার পর নমুনা উত্তর ও checklist মিলিয়ে নাও।"
      : null) ||
    (type === "comprehension_set"
      ? "অনুচ্ছেদটি মন দিয়ে পড়ে প্রশ্নগুলোর উত্তর দাও।"
      : null);
  if (!explanation) throw new Error(`missing "rule_bn" (Bangla explanation)`);

  const instruction = item.instruction_bn || ctx.defaults.instruction_bn;
  if (!instruction) throw new Error(`missing instruction_bn (set one on the file)`);

  return {
    // `batch` (optional, from the file) lets a topic span multiple files
    // without id collisions, e.g. topic-b001 vs the base topic-001.
    id: `${ctx.deck}.${type}.${ctx.topic}-${ctx.batch}${pad(ctx.seq)}`,
    type,
    paper: ctx.paper,
    topic: ctx.topic,
    ...(item.subtopic ? { subtopic: item.subtopic } : {}),
    difficulty: item.difficulty || ctx.defaults.difficulty,
    marks_weight: item.marks_weight || ctx.defaults.marks_weight,
    tags: item.tags || ctx.defaults.tags,
    instruction_bn: instruction,
    explanation_bn: explanation,
    review_status: item.review_status || ctx.defaults.review_status,
    author: item.author || ctx.defaults.author,
    data,
  };
}

function expandFile(filePath) {
  const doc = JSON.parse(fs.readFileSync(filePath, "utf8"));
  const base = path.basename(filePath);
  const paper = doc.paper || "both";
  const ctx = {
    topic: doc.topic,
    paper,
    deck: PAPER_DECK[paper] || "b",
    batch: doc.batch ? `${doc.batch}` : "",
    defaults: {
      difficulty: doc.difficulty || "easy",
      review_status: doc.review_status || "reviewed",
      author: doc.author || "ezpz-content",
      instruction_bn: doc.instruction_bn || "",
      marks_weight: doc.marks_weight || 1,
      tags: doc.tags || [],
    },
  };

  const entries = [];
  const errors = [];
  if (!doc.topic) {
    errors.push({ sheet: base, row: null, column: "topic", message: `authoring file has no "topic"` });
  }
  (doc.items || []).forEach((item, i) => {
    const source = { sheet: base, row: i + 1 };
    try {
      entries.push({ question: expandItem(item, { ...ctx, seq: i + 1 }), source });
    } catch (e) {
      errors.push({ sheet: base, row: i + 1, column: item.type || null, message: e.message });
    }
  });
  return { entries, errors };
}

/** Expands every *.json authoring file in a directory (sorted for stable ids). */
function expandDir(dir) {
  const files = fs
    .readdirSync(dir)
    .filter((f) => f.endsWith(".json"))
    .sort();
  const entries = [];
  const errors = [];
  for (const f of files) {
    const res = expandFile(path.join(dir, f));
    entries.push(...res.entries);
    errors.push(...res.errors);
  }
  return { entries, errors, files };
}

module.exports = { expandFile, expandDir, expandItem };
