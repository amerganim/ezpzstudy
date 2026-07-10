"use strict";

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const yaml = require("js-yaml");

const { readWorkbook } = require("./readSpreadsheet");
const { MAPPERS, mapComprehensionPassage, mapSubQuestion } = require("./mapRowToQuestion");
const { buildAjv, validateQuestion, validateManifest } = require("./validateSchema");
const { validateSemantics } = require("./validateSemantics");
const { TABS, COMPREHENSION_LINKABLE_TABS } = require("./columns");

const SCHEMA_VERSION = "1.0.0";
const STANDALONE_TABS = TABS; // flashcard, mcq, fill_in_word_bank, fill_in_open, matching, rearranging, grammar_transformation, writing_prompt
const ALL_TABS = [...STANDALONE_TABS, "comprehension_passages"];

function sha256(content) {
  return crypto.createHash("sha256").update(content).digest("hex");
}

function loadTopicMap(topicMapPath) {
  const raw = fs.readFileSync(topicMapPath, "utf8");
  return yaml.load(raw);
}

/**
 * Reads the workbook, maps every row, resolves comprehension_set nesting,
 * runs schema + semantic validation, and returns everything the CLI needs
 * to either report errors or write a pack + manifest.
 */
async function processWorkbook({ inputPath, topicMapPath }) {
  const sourceBuffer = fs.readFileSync(inputPath);
  const sourceSha256 = sha256(sourceBuffer);
  const topicMap = loadTopicMap(topicMapPath);

  const sheets = await readWorkbook(inputPath, ALL_TABS);

  const mappingErrors = [];
  const standaloneEntries = []; // { question, source } not yet claimed by a comprehension_set
  const linkableByPassage = new Map(); // passage_id -> [{ subOrder, tabName, row }]

  for (const tabName of STANDALONE_TABS) {
    const { rows, missing } = sheets[tabName];
    if (missing) {
      mappingErrors.push({ sheet: tabName, row: null, column: null, message: `tab "${tabName}" is missing from the workbook` });
      continue;
    }
    const mapper = MAPPERS[tabName];
    for (const row of rows) {
      if (COMPREHENSION_LINKABLE_TABS.includes(tabName) && row.passage_id) {
        const list = linkableByPassage.get(row.passage_id) || [];
        list.push({ subOrder: Number(row.sub_order) || 0, tabName, row });
        linkableByPassage.set(row.passage_id, list);
        continue;
      }
      const { question, errors } = mapper(row);
      mappingErrors.push(...errors);
      standaloneEntries.push({ question, source: { sheet: row.__sheet, row: row.__row } });
    }
  }

  // comprehension_passages -> comprehension_set questions, with nested sub_questions
  const { rows: passageRows, missing: passagesMissing } = sheets.comprehension_passages;
  const comprehensionEntries = [];
  const claimedPassageIds = new Set();
  if (!passagesMissing) {
    for (const row of passageRows) {
      const { question, errors } = mapComprehensionPassage(row);
      mappingErrors.push(...errors);
      const passageId = row.passage_id;
      claimedPassageIds.add(passageId);
      const linked = (linkableByPassage.get(passageId) || []).sort((a, b) => a.subOrder - b.subOrder);
      for (const { tabName, row: subRow } of linked) {
        const { subQuestion, errors: subErrors } = mapSubQuestion(tabName, subRow);
        mappingErrors.push(
          ...subErrors.map((e) => ({ ...e, message: `[nested under passage "${passageId}"] ${e.message}` }))
        );
        question.data.sub_questions.push(subQuestion);
      }
      if (question.data.sub_questions.length === 0) {
        mappingErrors.push({
          sheet: row.__sheet,
          row: row.__row,
          column: "passage_id",
          message: `passage "${passageId}" has no linked sub-questions (no row references it via passage_id)`,
        });
      }
      comprehensionEntries.push({ question, source: { sheet: row.__sheet, row: row.__row } });
    }
  }

  // any linkable row whose passage_id never matched a real passage
  for (const [passageId, rowsList] of linkableByPassage.entries()) {
    if (!claimedPassageIds.has(passageId)) {
      for (const { row } of rowsList) {
        mappingErrors.push({
          sheet: row.__sheet,
          row: row.__row,
          column: "passage_id",
          message: `passage_id "${passageId}" does not match any row in comprehension_passages`,
        });
      }
    }
  }

  const allEntries = [...standaloneEntries, ...comprehensionEntries];

  const ajv = buildAjv();
  const schemaErrors = [];
  for (const { question, source } of allEntries) {
    for (const e of validateQuestion(ajv, question)) {
      schemaErrors.push({ sheet: source.sheet, row: source.row, column: e.instancePath, message: e.message });
    }
  }

  const { errors: semanticErrors, warnings } = validateSemantics(allEntries, topicMap);

  const errors = [...mappingErrors, ...schemaErrors, ...semanticErrors];

  return { ajv, allEntries, errors, warnings, sourceSha256, topicMap };
}

function formatIssue(prefix, issue) {
  const loc = issue.row ? `${issue.sheet} row ${issue.row}` : issue.sheet;
  const col = issue.column ? ` (${issue.column})` : "";
  return `${prefix} [${loc}]${col}: ${issue.message}`;
}

function buildManifest({ packVersion, generatedAt, sourceFile, sourceSha256, packSha256, questions, errors, warnings }) {
  const by_type = {};
  const by_paper = {};
  for (const q of questions) {
    by_type[q.type] = (by_type[q.type] || 0) + 1;
    by_paper[q.paper] = (by_paper[q.paper] || 0) + 1;
  }
  return {
    pack_version: packVersion,
    schema_version: SCHEMA_VERSION,
    generated_at: generatedAt,
    source_file: sourceFile,
    source_sha256: sourceSha256,
    pack_sha256: packSha256,
    counts: { total: questions.length, by_type, by_paper },
    errors: errors.length,
    warnings: warnings.length,
  };
}

async function buildCommand({ inputPath, topicMapPath, outPath, packVersion }) {
  const { ajv, allEntries, errors, warnings, sourceSha256 } = await processWorkbook({ inputPath, topicMapPath });

  const report = [
    ...errors.map((e) => formatIssue("✖ error", e)),
    ...warnings.map((w) => formatIssue("⚠ warning", w)),
  ].join("\n");

  if (errors.length > 0) {
    return { ok: false, errors, warnings, report };
  }

  const questions = allEntries.map((e) => e.question).sort((a, b) => a.id.localeCompare(b.id));
  const packJson = JSON.stringify(questions, null, 2) + "\n";
  const packSha256 = sha256(packJson);

  const manifest = buildManifest({
    packVersion,
    generatedAt: new Date().toISOString(),
    sourceFile: path.basename(inputPath),
    sourceSha256,
    packSha256,
    questions,
    errors,
    warnings,
  });

  const manifestErrors = validateManifest(ajv, manifest);
  if (manifestErrors.length > 0) {
    return { ok: false, errors: manifestErrors.map((m) => ({ sheet: null, row: null, column: null, message: m })), warnings, report };
  }

  const outDir = path.dirname(outPath);
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(outPath, packJson, "utf8");

  const manifestPath = outPath.replace(/content_pack_v(\d+)\.json$/, "manifest_v$1.json");
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + "\n", "utf8");

  const reportPath = outPath.replace(/content_pack_v(\d+)\.json$/, "validation-report_v$1.txt");
  fs.writeFileSync(reportPath, report ? report + "\n" : "(no errors or warnings)\n", "utf8");

  return { ok: true, manifest, outPath, manifestPath, reportPath, report, warnings };
}

async function validateCommand({ inputPath, topicMapPath }) {
  const { errors, warnings } = await processWorkbook({ inputPath, topicMapPath });
  const report = [
    ...errors.map((e) => formatIssue("✖ error", e)),
    ...warnings.map((w) => formatIssue("⚠ warning", w)),
  ].join("\n");
  return { ok: errors.length === 0, errors, warnings, report };
}

module.exports = { processWorkbook, buildCommand, validateCommand, formatIssue };
