"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { makeTestApp } = require("./helpers/memoryDb");
const { verifyToken } = require("../src/lib/token");

test("health responds", async () => {
  const { app, pool } = await makeTestApp();
  const res = await app.inject({ method: "GET", url: "/health" });
  assert.equal(res.statusCode, 200);
  await app.close();
  await pool.end();
});

test("auth creates a new student and issues a valid token", async () => {
  const { app, pool, config } = await makeTestApp();
  const res = await app.inject({
    method: "POST",
    url: "/auth",
    payload: { phone: "01700000000", name: "Rahim", school_code: "SCH-1" },
  });
  assert.equal(res.statusCode, 200);
  const body = res.json();
  assert.equal(body.student.phone, "01700000000");
  assert.equal(body.student.name, "Rahim");
  assert.equal(body.student.school_code, "SCH-1");

  const payload = verifyToken(body.token, config.tokenSecret);
  assert.ok(payload, "token should verify");
  assert.equal(payload.sub, body.student.id);
  await app.close();
  await pool.end();
});

test("auth is idempotent per phone (find-or-create, same id)", async () => {
  const { app, pool } = await makeTestApp();
  const first = await app.inject({
    method: "POST",
    url: "/auth",
    payload: { phone: "01711111111" },
  });
  const second = await app.inject({
    method: "POST",
    url: "/auth",
    payload: { phone: "01711111111", name: "Karim" },
  });
  assert.equal(first.json().student.id, second.json().student.id);
  // Second call fills in the newly provided name without creating a duplicate.
  assert.equal(second.json().student.name, "Karim");

  const count = await pool.query("SELECT count(*)::int AS n FROM students");
  assert.equal(count.rows[0].n, 1);
  await app.close();
  await pool.end();
});

test("auth rejects a missing phone", async () => {
  const { app, pool } = await makeTestApp();
  const res = await app.inject({
    method: "POST",
    url: "/auth",
    payload: { name: "No Phone" },
  });
  assert.equal(res.statusCode, 400);
  await app.close();
  await pool.end();
});
