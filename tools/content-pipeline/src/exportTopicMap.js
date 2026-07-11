"use strict";

const fs = require("fs");
const yaml = require("js-yaml");

// Every section that holds topics the app needs to know about. Paper/track are
// read from the section itself (with a per-section fallback here).
const SECTIONS = [
  "basics",
  "paper_1st_reading",
  "paper_1st_writing",
  "paper_2nd_grammar",
  "paper_2nd_writing",
  "cross_cutting",
];

/// Compiles topic-map.yaml into a compact JSON the app bundles and reads for
/// the weighted Predicted Board Score and Focus Areas routing. Keeping the YAML
/// authoritative and generating the JSON means the app never drifts from the
/// numbers teachers validate.
function compileTopicMap(topicMapPath) {
  const topicMap = yaml.load(fs.readFileSync(topicMapPath, "utf8"));

  const topics = [];
  for (const section of SECTIONS) {
    const sec = topicMap[section];
    const list = sec && sec.topics;
    if (!Array.isArray(list)) continue;
    const sectionPaper = sec.paper || "both";
    const sectionTrack = sec.track || "hsc";
    for (const t of list) {
      topics.push({
        id: t.id,
        label_en: t.label_en,
        label_bn: t.label_bn || t.label_en,
        track: t.track || sectionTrack,
        paper: t.paper || sectionPaper,
        weight: typeof t.weight === "number" ? t.weight : 0,
        remedial: Array.isArray(t.remedial) ? t.remedial : [],
      });
    }
  }

  const remedialLabels = {};
  if (Array.isArray(topicMap.remedial_topics)) {
    for (const t of topicMap.remedial_topics) {
      remedialLabels[t.id] = t.label_en;
    }
  }

  return {
    schema_version: topicMap.schema_version || "unknown",
    generated_at: new Date().toISOString(),
    topics,
    remedial_labels: remedialLabels,
  };
}

function exportTopicMap(topicMapPath, outPath) {
  const compiled = compileTopicMap(topicMapPath);
  fs.writeFileSync(outPath, JSON.stringify(compiled, null, 2) + "\n", "utf8");
  return { outPath, topicCount: compiled.topics.length };
}

module.exports = { compileTopicMap, exportTopicMap };
