"use strict";

const path = require("path");
const Ajv2020 = require("ajv/dist/2020");
const addFormats = require("ajv-formats");

const SCHEMA_DIR = path.join(__dirname, "..", "..", "..", "content", "schema");

function buildAjv() {
  const ajv = new Ajv2020({ allErrors: true, strict: false });
  addFormats(ajv);
  const questionSchema = require(path.join(SCHEMA_DIR, "question-schema.json"));
  const packSchema = require(path.join(SCHEMA_DIR, "content-pack-schema.json"));
  ajv.addSchema(questionSchema, "question-schema.json");
  ajv.addSchema(packSchema, "content-pack-schema.json");
  return ajv;
}

function validateQuestion(ajv, question) {
  const validate = ajv.getSchema("question-schema.json");
  const valid = validate(question);
  if (valid) return [];
  return (validate.errors || []).map((e) => ({
    instancePath: e.instancePath,
    message: `${e.instancePath || "(root)"} ${e.message}`,
  }));
}

function validateManifest(ajv, manifest) {
  const packSchema = ajv.getSchema("content-pack-schema.json");
  const manifestSchema = { $ref: "content-pack-schema.json#/$defs/manifest" };
  const validate = ajv.compile(manifestSchema);
  const valid = validate(manifest);
  if (valid) return [];
  return (validate.errors || []).map((e) => `${e.instancePath || "(root)"} ${e.message}`);
}

module.exports = { buildAjv, validateQuestion, validateManifest };
