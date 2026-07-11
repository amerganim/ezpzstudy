"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const path = require("path");
const fs = require("fs");
const os = require("os");

const { validateCommand, buildCommand, buildJsonCommand, validateEntries } = require("../src/buildPack");
const { exportTopicMap, compileTopicMap } = require("../src/exportTopicMap");
const { expandDir } = require("../src/authoring");
const yaml = require("js-yaml");

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

test("topic-map compile carries real marks, tracks, and Bangla labels", () => {
  const compiled = compileTopicMap(TOPIC_MAP);
  assert.ok(compiled.topics.length > 0);

  // An HSC exam item carries its real 2025 board weight, paper, track, label_bn.
  const prep = compiled.topics.find((t) => t.id === "p2_preposition");
  assert.ok(prep, "expected the preposition exam item");
  assert.equal(prep.paper, "2nd");
  assert.equal(prep.weight, 5);
  assert.equal(prep.track, "hsc");
  assert.ok(prep.label_bn, "expected a Bangla label");

  // A basics-track foundation is weight 0 (not a board item) and track=basics.
  const basics = compiled.topics.find((t) => t.id === "basics_sentence_structure");
  assert.ok(basics, "expected a basics topic");
  assert.equal(basics.weight, 0);
  assert.equal(basics.track, "basics");

  // Vocabulary is cross-cutting: present, weight 0 so it never distorts the score.
  const vocab = compiled.topics.find((t) => t.id === "vocabulary_hsc_words");
  assert.ok(vocab, "expected the vocabulary topic");
  assert.equal(vocab.weight, 0);

  // The full board weight across hsc scoring items is the real 200 (100+100).
  const totalWeight = compiled.topics
    .filter((t) => t.weight > 0)
    .reduce((s, t) => s + t.weight, 0);
  assert.equal(totalWeight, 200);
});

test("topic-map export writes a JSON file the app can load", () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "ezpz-topicmap-test-"));
  const outPath = path.join(tmpDir, "topic_map.json");
  const { topicCount } = exportTopicMap(TOPIC_MAP, outPath);
  assert.ok(topicCount > 0);
  const parsed = JSON.parse(fs.readFileSync(outPath, "utf8"));
  assert.equal(parsed.topics.length, topicCount);
  assert.ok(Array.isArray(parsed.topics));
  assert.ok(parsed.remedial_labels && typeof parsed.remedial_labels === "object");
});

test("JSON authoring expands and validates across item types", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ezpz-authoring-"));
  fs.writeFileSync(
    path.join(dir, "prep.json"),
    JSON.stringify({
      topic: "p2_preposition",
      paper: "2nd",
      instruction_bn: "শূন্যস্থানে সঠিক preposition বসাও।",
      items: [
        { type: "fill_in_open", q: "He is good ___ maths.", a: ["at"], rule_bn: "good-এর পরে at বসে।" },
        { type: "mcq", q: "She ___ to school.", opts: ["go", "goes", "going", "gone"], correct: 1, rule_bn: "third person singular-এ verb-এ s যোগ হয়।" },
        { type: "rearranging", answer: "I am a student", rule_bn: "সঠিক ক্রম।" },
      ],
    })
  );

  const topicMap = yaml.load(fs.readFileSync(TOPIC_MAP, "utf8"));
  const { entries, errors: expandErrors } = expandDir(dir);
  assert.equal(expandErrors.length, 0, JSON.stringify(expandErrors));
  assert.equal(entries.length, 3);

  // id follows the schema pattern deck.type.slug
  assert.match(entries[0].question.id, /^p2\.fill_in_open\.p2_preposition-\d+$/);
  // mcq index -> letter key
  assert.equal(entries[1].question.data.correct_option, "B");
  // rearranging split into ordered units
  assert.equal(entries[2].question.data.units.length, 4);

  const { errors } = validateEntries(entries, topicMap);
  assert.equal(errors.length, 0, JSON.stringify(errors));
});

test("JSON authoring reports a bad item without crashing the build", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ezpz-authoring-bad-"));
  fs.writeFileSync(
    path.join(dir, "bad.json"),
    JSON.stringify({
      topic: "p2_preposition",
      paper: "2nd",
      instruction_bn: "…",
      items: [
        { type: "fill_in_open", q: "no answer here ___.", rule_bn: "x" }, // missing "a"
      ],
    })
  );
  const outPath = path.join(dir, "content_pack_v9.json");
  const result = buildJsonCommand({
    authoringDir: dir,
    topicMapPath: TOPIC_MAP,
    outPath,
    packVersion: 9,
  });
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => /missing "a"/.test(e.message)));
  assert.equal(fs.existsSync(outPath), false);
});
