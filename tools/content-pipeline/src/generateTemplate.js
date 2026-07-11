"use strict";

const fs = require("fs");
const ExcelJS = require("exceljs");
const yaml = require("js-yaml");
const { TABS, COMPREHENSION_PASSAGE_COLUMNS, DROPDOWNS, tabColumns } = require("./columns");

const HEADER_FILL = { type: "pattern", pattern: "solid", fgColor: { argb: "FFD9E8F5" } };

function collectTopicRows(topicMap) {
  const rows = [];
  const sections = [
    ["basics", "both", "foundations"],
    ["paper_1st_reading", "1st", "reading"],
    ["paper_1st_writing", "1st", "guided_writing"],
    ["paper_2nd_grammar", "2nd", "grammar"],
    ["paper_2nd_writing", "2nd", "composition"],
    ["cross_cutting", "both", "vocabulary"],
  ];
  for (const [key, paper, section] of sections) {
    const sec = topicMap[key];
    const topics = sec && sec.topics;
    if (Array.isArray(topics)) {
      for (const t of topics) {
        rows.push([t.id, t.label_en, t.paper || sec.paper || paper, section]);
      }
    }
  }
  return rows;
}

function addHeaderRow(sheet, columns) {
  const row = sheet.addRow(columns);
  row.eachCell((cell) => {
    cell.font = { bold: true };
    cell.fill = HEADER_FILL;
  });
  sheet.views = [{ state: "frozen", ySplit: 1 }];
  sheet.columns.forEach((col) => {
    col.width = 22;
  });
}

function applyDropdown(sheet, columnIndex, listOrFormula, isRange, startRow, endRow) {
  const formulae = isRange ? [listOrFormula] : [`"${listOrFormula.join(",")}"`];
  for (let r = startRow; r <= endRow; r++) {
    sheet.getCell(r, columnIndex).dataValidation = {
      type: "list",
      allowBlank: true,
      formulae,
      showErrorMessage: true,
      errorStyle: "warning",
      errorTitle: "Invalid value",
      error: "Please choose a value from the dropdown list.",
    };
  }
}

const DATA_ROWS = 500; // dropdown validation applied to this many blank rows below the header

async function generateTemplate(outputPath, topicMapPath) {
  const topicMap = yaml.load(fs.readFileSync(topicMapPath, "utf8"));
  const workbook = new ExcelJS.Workbook();
  workbook.creator = "EZPZ Study content pipeline";
  workbook.created = new Date();

  // README tab first so it's the tab teachers see on open
  const readme = workbook.addWorksheet("README");
  readme.getColumn(1).width = 100;
  const lines = [
    "EZPZ Study — Content Authoring Template / শিক্ষকের জন্য নির্দেশিকা",
    "",
    "English: One tab per question type. Fill one row per question. Do not rename column headers.",
    "Do not delete the header row. Leave a column blank if it does not apply to your question.",
    "The 'topic' column dropdown lists valid topics from the current topic map -- always pick from it.",
    "'review_status' should stay 'draft' until a fellow teacher reviews the item, then set to 'reviewed' or 'published'.",
    "",
    "বাংলা: প্রতিটা প্রশ্নের ধরনের জন্য একটি আলাদা ট্যাব আছে। প্রতি সারিতে একটি প্রশ্ন লিখুন।",
    "কলামের শিরোনাম পরিবর্তন করবেন না। প্রযোজন না হলে ঘর খালি রাখুন।",
    "",
    "Tabs / ট্যাবসমূহ: " + [...TABS, "comprehension_passages"].join(", "),
  ];
  lines.forEach((line) => readme.addRow([line]));

  // topics reference tab (also the dropdown source range for `topic` columns)
  const topicsSheet = workbook.addWorksheet("topics");
  topicsSheet.addRow(["topic_id", "label_en", "paper", "section"]).eachCell((c) => {
    c.font = { bold: true };
    c.fill = HEADER_FILL;
  });
  const topicRows = collectTopicRows(topicMap);
  for (const r of topicRows) topicsSheet.addRow(r);
  topicsSheet.columns.forEach((col) => (col.width = 28));
  const topicRangeFormula = `topics!$A$2:$A$${topicRows.length + 1}`;

  for (const tabName of TABS) {
    const sheet = workbook.addWorksheet(tabName);
    const columns = tabColumns(tabName);
    addHeaderRow(sheet, columns);

    columns.forEach((colName, idx) => {
      const columnIndex = idx + 1;
      if (colName === "topic") {
        applyDropdown(sheet, columnIndex, topicRangeFormula, true, 2, DATA_ROWS);
      } else if (DROPDOWNS[colName]) {
        applyDropdown(sheet, columnIndex, DROPDOWNS[colName], false, 2, DATA_ROWS);
      }
    });
  }

  // comprehension_passages tab
  const passagesSheet = workbook.addWorksheet("comprehension_passages");
  addHeaderRow(passagesSheet, COMPREHENSION_PASSAGE_COLUMNS);
  COMPREHENSION_PASSAGE_COLUMNS.forEach((colName, idx) => {
    const columnIndex = idx + 1;
    if (colName === "topic") {
      applyDropdown(passagesSheet, columnIndex, topicRangeFormula, true, 2, DATA_ROWS);
    } else if (DROPDOWNS[colName]) {
      applyDropdown(passagesSheet, columnIndex, DROPDOWNS[colName], false, 2, DATA_ROWS);
    }
  });

  await workbook.xlsx.writeFile(outputPath);
  return outputPath;
}

module.exports = { generateTemplate };
