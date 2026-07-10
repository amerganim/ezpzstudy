"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const path = require("path");
const fs = require("fs");
const os = require("os");

const { validateCommand, buildCommand } = require("../src/buildPack");

const TOPIC_MAP = path.join(__dirname, "..", "..", "..", "content", "topic-map", "topic-map.yaml");
const VALID_SAMPLE = path.join(__dirname, "fixtures", "valid-sample.xlsx");
const BROKEN_SAMPLE = path.join(__dirname, "fixtures", "broken-sample.xlsx");

test("valid-sample.xlsx passes validation with no errors", async () => {
  const result = await validateCommand({ inputPath: VALID_SAMPLE, topicMapPath: TOPIC_MAP });
  assert.equal(result.ok, true);
  assert.equal(result.errors.length, 0);
});

test("valid-sample.xlsx builds a pack with all 3 questions", async () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "ezpz-pipeline-test-"));
  const outPath = path.join(tmpDir, "content_pack_v1.json");
  const result = await buildCommand({
    inputPath: VALID_SAMPLE,
    topicMapPath: TOPIC_MAP,
    outPath,
    packVersion: 1,
  });
  assert.equal(result.ok, true);
  assert.equal(result.manifest.counts.total, 3);
  const pack = JSON.parse(fs.readFileSync(outPath, "utf8"));
  assert.equal(pack.length, 3);
  const mcq = pack.find((q) => q.type === "mcq");
  assert.equal(mcq.data.correct_option, "B");
  assert.equal(mcq.data.options.length, 4);
});

test("broken-sample.xlsx fails validation with the expected error classes", async () => {
  const result = await validateCommand({ inputPath: BROKEN_SAMPLE, topicMapPath: TOPIC_MAP });
  assert.equal(result.ok, false);

  const messages = result.errors.map((e) => e.message);

  assert.ok(
    messages.some((m) => m.includes('correct_option "E" does not match any option key')),
    "expected an invalid correct_option error"
  );
  assert.ok(
    messages.some((m) => m.includes("duplicate id")),
    "expected a duplicate id error"
  );
  assert.ok(
    messages.some((m) => m.includes('topic "not_a_real_topic" is not defined')),
    "expected an unknown topic error"
  );
  assert.ok(
    messages.some((m) => m.includes("blank {{2}} in sentence_en has no answer_2 value")),
    "expected an unmatched fill-in blank error"
  );
  assert.ok(
    messages.some((m) => m.includes("left and right columns must be filled in pairs")),
    "expected a mismatched matching pair error"
  );

  for (const e of result.errors) {
    assert.ok(e.sheet, "every error must carry a sheet reference");
  }
});

test("broken-sample.xlsx build refuses to write a pack", async () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "ezpz-pipeline-test-"));
  const outPath = path.join(tmpDir, "content_pack_v1.json");
  const result = await buildCommand({
    inputPath: BROKEN_SAMPLE,
    topicMapPath: TOPIC_MAP,
    outPath,
    packVersion: 1,
  });
  assert.equal(result.ok, false);
  assert.equal(fs.existsSync(outPath), false);
});
