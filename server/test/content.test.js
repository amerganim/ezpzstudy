"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { makeTestApp } = require("./helpers/memoryDb");

test("content/version returns 0 when nothing is registered", async () => {
  const { app, pool } = await makeTestApp();
  const res = await app.inject({ method: "GET", url: "/content/version" });
  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.json(), { latest_version: 0, min_supported_version: 0 });
  await app.close();
  await pool.end();
});

test("content/version reports the latest registered version", async () => {
  const { app, pool } = await makeTestApp();
  await pool.query(
    "INSERT INTO content_versions (version, min_supported) VALUES (1, 1), (2, 1)"
  );
  const res = await app.inject({ method: "GET", url: "/content/version" });
  assert.deepEqual(res.json(), { latest_version: 2, min_supported_version: 1 });
  await app.close();
  await pool.end();
});

test("content/pack is disabled without CONTENT_DIR", async () => {
  const { app, pool } = await makeTestApp();
  const res = await app.inject({ method: "GET", url: "/content/pack?version=1" });
  assert.equal(res.statusCode, 404);
  await app.close();
  await pool.end();
});

test("content/pack serves the requested version file when CONTENT_DIR is set", async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ezpz-content-"));
  fs.writeFileSync(
    path.join(dir, "content_pack_v1.json"),
    JSON.stringify([{ id: "q1" }])
  );

  const { app, pool } = await makeTestApp({ config: { contentDir: dir } });
  await pool.query("INSERT INTO content_versions (version, min_supported) VALUES (1, 1)");

  const res = await app.inject({ method: "GET", url: "/content/pack?version=1" });
  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.json(), [{ id: "q1" }]);

  const missing = await app.inject({ method: "GET", url: "/content/pack?version=99" });
  assert.equal(missing.statusCode, 404);
  await app.close();
  await pool.end();
});
