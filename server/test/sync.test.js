"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { makeTestApp } = require("./helpers/memoryDb");

async function authed(app) {
  const res = await app.inject({
    method: "POST",
    url: "/auth",
    payload: { phone: "01700000000", name: "Rahim" },
  });
  const body = res.json();
  return { token: body.token, studentId: body.student.id };
}

function syncPayload(overrides = {}) {
  return {
    since: "2026-07-01T00:00:00Z",
    topic_progress: [
      { topic: "narration", attempts: 60, correct: 21, last_practiced: "2026-07-10T00:00:00Z" },
      { topic: "tense", attempts: 40, correct: 33, last_practiced: "2026-07-10T00:00:00Z" },
    ],
    streak_days: 12,
    sessions: 9,
    ...overrides,
  };
}

test("sync requires a bearer token", async () => {
  const { app, pool } = await makeTestApp();
  const res = await app.inject({ method: "POST", url: "/sync", payload: syncPayload() });
  assert.equal(res.statusCode, 401);
  await app.close();
  await pool.end();
});

test("sync rejects an invalid token", async () => {
  const { app, pool } = await makeTestApp();
  const res = await app.inject({
    method: "POST",
    url: "/sync",
    headers: { authorization: "Bearer not.a.token" },
    payload: syncPayload(),
  });
  assert.equal(res.statusCode, 401);
  await app.close();
  await pool.end();
});

test("sync stores per-topic aggregates and updates streak/sessions", async () => {
  const { app, pool } = await makeTestApp();
  const { token, studentId } = await authed(app);

  const res = await app.inject({
    method: "POST",
    url: "/sync",
    headers: { authorization: `Bearer ${token}` },
    payload: syncPayload(),
  });
  assert.equal(res.statusCode, 200);
  assert.equal(res.json().synced_topics, 2);

  const rows = await pool.query(
    "SELECT topic, attempts, correct FROM topic_progress WHERE student_id = $1 ORDER BY topic",
    [studentId]
  );
  assert.deepEqual(
    rows.rows.map((r) => [r.topic, r.attempts, r.correct]),
    [
      ["narration", 60, 21],
      ["tense", 40, 33],
    ]
  );

  const student = await pool.query(
    "SELECT streak_days, sessions, last_sync_at FROM students WHERE id = $1",
    [studentId]
  );
  assert.equal(student.rows[0].streak_days, 12);
  assert.equal(student.rows[0].sessions, 9);
  assert.ok(student.rows[0].last_sync_at, "last_sync_at should be set");
  await app.close();
  await pool.end();
});

test("re-syncing the same topic replaces the aggregate (no per-attempt rows)", async () => {
  const { app, pool } = await makeTestApp();
  const { token, studentId } = await authed(app);

  await app.inject({
    method: "POST",
    url: "/sync",
    headers: { authorization: `Bearer ${token}` },
    payload: syncPayload({
      topic_progress: [{ topic: "tense", attempts: 40, correct: 33 }],
    }),
  });
  // A later sync sends the newer cumulative totals for the same topic.
  await app.inject({
    method: "POST",
    url: "/sync",
    headers: { authorization: `Bearer ${token}` },
    payload: syncPayload({
      topic_progress: [{ topic: "tense", attempts: 55, correct: 47 }],
    }),
  });

  const rows = await pool.query(
    "SELECT attempts, correct FROM topic_progress WHERE student_id = $1 AND topic = 'tense'",
    [studentId]
  );
  // One row, replaced — never one row per attempt.
  assert.equal(rows.rows.length, 1);
  assert.deepEqual([rows.rows[0].attempts, rows.rows[0].correct], [55, 47]);
  await app.close();
  await pool.end();
});

test("sync rejects a body student_id that mismatches the token", async () => {
  const { app, pool } = await makeTestApp();
  const { token } = await authed(app);
  const res = await app.inject({
    method: "POST",
    url: "/sync",
    headers: { authorization: `Bearer ${token}` },
    payload: syncPayload({ student_id: "someone-else" }),
  });
  assert.equal(res.statusCode, 403);
  await app.close();
  await pool.end();
});

test("sync rejects invalid aggregates (correct > attempts)", async () => {
  const { app, pool } = await makeTestApp();
  const { token } = await authed(app);
  const res = await app.inject({
    method: "POST",
    url: "/sync",
    headers: { authorization: `Bearer ${token}` },
    payload: syncPayload({
      topic_progress: [{ topic: "tense", attempts: 5, correct: 9 }],
    }),
  });
  assert.equal(res.statusCode, 400);
  await app.close();
  await pool.end();
});
