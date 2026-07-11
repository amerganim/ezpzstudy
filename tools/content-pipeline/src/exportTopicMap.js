"use strict";

const fs = require("fs");
const yaml = require("js-yaml");

// Sections of the topic map that hold board-scorable topics, with the paper
// they belong to. Vocabulary is cross-cutting and not a direct board-marks input.
const WEIGHTED_SECTIONS = [
  ["paper_1st", "1st"],
  ["paper_1st_writing", "1st"],
  ["paper_2nd_grammar", "2nd"],
  ["paper_2nd_writing", "2nd"],
];

/// Compiles topic-map.yaml into a compact JSON the app bundles and reads for
/// the weighted Predicted Board Score and Focus Areas routing. Keeping the YAML
/// authoritative and generating the JSON means the app never drifts from the
/// numbers teachers validate.
function compileTopicMap(topicMapPath) {
  const topicMap = yaml.load(fs.readFileSync(topicMapPath, "utf8"));

  const topics = [];
  for (const [section, paper] of WEIGHTED_SECTIONS) {
    const list = topicMap[section] && topicMap[section].topics;
    if (!Array.isArray(list)) continue;
    for (const t of list) {
      topics.push({
        id: t.id,
        label_en: t.label_en,
        paper,
        weight: typeof t.weight === "number" ? t.weight : 0,
        remedial: Array.isArray(t.remedial) ? t.remedial : [],
      });
    }
  }

  // Cross-cutting (vocabulary) topics: included so the app knows about them,
  // but weight 0 so they don't distort the board-score projection.
  const cross = topicMap.cross_cutting && topicMap.cross_cutting.topics;
  if (Array.isArray(cross)) {
    for (const t of cross) {
      topics.push({
        id: t.id,
        label_en: t.label_en,
        paper: t.paper === "both" ? "both" : (t.paper || "both"),
        weight: 0,
        remedial: [],
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
