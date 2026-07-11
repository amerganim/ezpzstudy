#!/usr/bin/env node
"use strict";

const path = require("path");
const { parseArgs } = require("node:util");
const { buildCommand, buildJsonCommand, validateCommand } = require("./buildPack");
const { generateTemplate } = require("./generateTemplate");
const { exportTopicMap } = require("./exportTopicMap");

const DEFAULT_TOPIC_MAP = path.join(__dirname, "..", "..", "..", "content", "topic-map", "topic-map.yaml");

function printUsage() {
  console.error(
    [
      "Usage:",
      "  node src/index.js validate --input <workbook.xlsx> [--topic-map <topic-map.yaml>]",
      "  node src/index.js build --input <workbook.xlsx> [--topic-map <topic-map.yaml>] --out <content_pack_vN.json> --pack-version <N>",
      "  node src/index.js build-json --dir <authoring-dir> [--topic-map <topic-map.yaml>] --out <content_pack_vN.json> --pack-version <N>",
      "  node src/index.js template --out <template.xlsx> [--topic-map <topic-map.yaml>]",
      "  node src/index.js topic-map --out <topic_map.json> [--topic-map <topic-map.yaml>]",
    ].join("\n")
  );
}

async function main() {
  const [command, ...rest] = process.argv.slice(2);

  const known = ["validate", "build", "build-json", "template", "topic-map"];
  if (!known.includes(command)) {
    printUsage();
    process.exit(1);
  }

  const { values } = parseArgs({
    args: rest,
    options: {
      input: { type: "string" },
      dir: { type: "string" },
      "topic-map": { type: "string", default: DEFAULT_TOPIC_MAP },
      out: { type: "string" },
      "pack-version": { type: "string" },
    },
  });

  if (command === "build-json") {
    if (!values.dir || !values.out || !values["pack-version"]) {
      console.error("Error: --dir, --out and --pack-version are required for build-json");
      printUsage();
      process.exit(1);
    }
    const result = buildJsonCommand({
      authoringDir: values.dir,
      topicMapPath: values["topic-map"],
      outPath: values.out,
      packVersion: Number(values["pack-version"]),
    });
    if (result.report) console.log(result.report);
    if (!result.ok) {
      console.log(`\nBuild failed: ${result.errors.length} error(s). No pack written.`);
      process.exit(1);
    }
    console.log(`\nBuild succeeded: ${result.manifest.counts.total} question(s) written to ${result.outPath}`);
    console.log(`Manifest: ${result.manifestPath}`);
    process.exit(0);
  }

  if (command === "template") {
    if (!values.out) {
      console.error("Error: --out is required for template");
      printUsage();
      process.exit(1);
    }
    const outPath = await generateTemplate(values.out, values["topic-map"]);
    console.log(`Template written to ${outPath}`);
    process.exit(0);
  }

  if (command === "topic-map") {
    if (!values.out) {
      console.error("Error: --out is required for topic-map");
      printUsage();
      process.exit(1);
    }
    const { outPath, topicCount } =
        exportTopicMap(values["topic-map"], values.out);
    console.log(`Topic map (${topicCount} topics) written to ${outPath}`);
    process.exit(0);
  }

  if (!values.input) {
    console.error("Error: --input is required");
    printUsage();
    process.exit(1);
  }

  if (command === "validate") {
    const result = await validateCommand({ inputPath: values.input, topicMapPath: values["topic-map"] });
    if (result.report) console.log(result.report);
    console.log(result.ok ? "\nValidation passed: 0 errors." : `\nValidation failed: ${result.errors.length} error(s).`);
    process.exit(result.ok ? 0 : 1);
  }

  if (command === "build") {
    if (!values.out || !values["pack-version"]) {
      console.error("Error: --out and --pack-version are required for build");
      printUsage();
      process.exit(1);
    }
    const result = await buildCommand({
      inputPath: values.input,
      topicMapPath: values["topic-map"],
      outPath: values.out,
      packVersion: Number(values["pack-version"]),
    });
    if (result.report) console.log(result.report);
    if (!result.ok) {
      console.log(`\nBuild failed: ${result.errors.length} error(s). No pack written.`);
      process.exit(1);
    }
    console.log(`\nBuild succeeded: ${result.manifest.counts.total} question(s) written to ${result.outPath}`);
    console.log(`Manifest: ${result.manifestPath}`);
    process.exit(0);
  }
}

main().catch((err) => {
  console.error("Unexpected error:", err);
  process.exit(1);
});
