"use strict";

// One-off generator for the two test fixtures. Run manually whenever the
// column layout changes:
//   node test/fixtures/build-fixtures.js
// The resulting .xlsx files are committed so tests don't need to regenerate
// them (and so a diff shows exactly what changed in the fixture data).

const path = require("path");
const ExcelJS = require("exceljs");
const { TABS, COMPREHENSION_PASSAGE_COLUMNS, tabColumns } = require("../../src/columns");

async function buildWorkbook(rowsByTab, passageRows) {
  const workbook = new ExcelJS.Workbook();

  for (const tabName of TABS) {
    const sheet = workbook.addWorksheet(tabName);
    const columns = tabColumns(tabName);
    sheet.addRow(columns);
    for (const rowData of rowsByTab[tabName] || []) {
      sheet.addRow(columns.map((c) => (rowData[c] !== undefined ? rowData[c] : "")));
    }
  }

  const passagesSheet = workbook.addWorksheet("comprehension_passages");
  passagesSheet.addRow(COMPREHENSION_PASSAGE_COLUMNS);
  for (const rowData of passageRows || []) {
    passagesSheet.addRow(COMPREHENSION_PASSAGE_COLUMNS.map((c) => (rowData[c] !== undefined ? rowData[c] : "")));
  }

  return workbook;
}

const COMMON = {
  paper: "2nd",
  topic: "tense",
  difficulty: "easy",
  marks_weight: 1,
  tags: "exam-common",
  instruction_bn: "সঠিক উত্তর বেছে নাও",
  explanation_bn: "Present perfect = have/has + V3.",
  review_status: "draft",
  author: "test-fixture",
};

async function buildValidSample() {
  const rowsByTab = {
    mcq: [
      {
        ...COMMON,
        id: "valid-mcq-01",
        question_en: "She ___ to school every day.",
        option_a: "go",
        option_b: "goes",
        option_c: "going",
        option_d: "gone",
        correct_option: "B",
      },
    ],
    fill_in_word_bank: [
      {
        ...COMMON,
        id: "valid-fiwb-01",
        sentence_en: "He {{1}} to the market yesterday.",
        word_bank: "went,goes,go",
        answer_1: "went",
      },
    ],
    flashcard: [
      {
        ...COMMON,
        id: "valid-flash-01",
        topic: "vocabulary_hsc_words",
        front_en: "Abundant",
        back_bn: "প্রচুর",
      },
    ],
  };
  const workbook = await buildWorkbook(rowsByTab, []);
  await workbook.xlsx.writeFile(path.join(__dirname, "valid-sample.xlsx"));
}

async function buildBrokenSample() {
  const rowsByTab = {
    mcq: [
      {
        ...COMMON,
        id: "broken-mcq-01",
        question_en: "She ___ to school every day.",
        option_a: "go",
        option_b: "goes",
        option_c: "going",
        option_d: "gone",
        correct_option: "E", // error: no option E exists
      },
      {
        ...COMMON,
        id: "broken-mcq-01", // error: duplicate id (same as row above)
        question_en: "They ___ happy.",
        option_a: "is",
        option_b: "are",
        correct_option: "B",
      },
      {
        ...COMMON,
        id: "broken-mcq-03",
        topic: "not_a_real_topic", // error: topic not in topic-map.yaml
        question_en: "I ___ a student.",
        option_a: "am",
        option_b: "is",
        correct_option: "A",
      },
    ],
    fill_in_word_bank: [
      {
        ...COMMON,
        id: "broken-fiwb-01",
        sentence_en: "He {{1}} to the market and then {{2}} home.", // error: no answer_2
        word_bank: "went,goes,go",
        answer_1: "went",
      },
    ],
    matching: [
      {
        ...COMMON,
        id: "broken-matching-01",
        left_1: "Tense",
        right_1: "Grammar of time",
        left_2: "Voice",
        // error: right_2 left blank while left_2 is filled
      },
    ],
  };
  const workbook = await buildWorkbook(rowsByTab, []);
  await workbook.xlsx.writeFile(path.join(__dirname, "broken-sample.xlsx"));
}

async function main() {
  await buildValidSample();
  await buildBrokenSample();
  console.log("Fixtures written: valid-sample.xlsx, broken-sample.xlsx");
}

main();
