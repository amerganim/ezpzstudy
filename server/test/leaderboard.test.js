"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { makeTestApp } = require("./helpers/memoryDb");
const { isoWeek } = require("../src/lib/week");

async function register(app, { phone, name, schoolCode }) {
  const res = await app.inject({
    method: "POST",
    url: "/auth",
    payload: { phone, name, school_code: schoolCode },
  });
  const body = res.json();
  return { token: body.token, id: body.student.id };
}

async function sync(app, token, topics) {
  return app.inject({
    method: "POST",
    url: "/sync",
    headers: { authorization: `Bearer ${token}` },
    payload: { topic_progress: topics, streak_days: 1, sessions: 1 },
  });
}

test("isoWeek formats an ISO week id", () => {
  assert.match(isoWeek(new Date("2026-07-11T00:00:00Z")), /^2026-W\d\d$/);
});

test("leaderboard requires auth", async () => {
  const { app, pool } = await makeTestApp();
  const res = await app.inject({ method: "GET", url: "/leaderboard" });
  assert.equal(res.statusCode, 401);
  await app.close();
  await pool.end();
});

test("a student with no school code gets an unscoped, empty board", async () => {
  const { app, pool } = await makeTestApp();
  const me = await register(app, { phone: "01700000000", name: "Solo" });
  const res = await app.inject({
    method: "GET",
    url: "/leaderboard",
    headers: { authorization: `Bearer ${me.token}` },
  });
  const body = res.json();
  assert.equal(body.scoped, false);
  assert.deepEqual(body.entries, []);
  await app.close();
  await pool.end();
});

test("weekly points accrue from correct-answer deltas and rank within a school", async () => {
  const { app, pool } = await makeTestApp();
  const rahim = await register(app, {
    phone: "01700000001",
    name: "Rahim",
    schoolCode: "SCH-1",
  });
  const karim = await register(app, {
    phone: "01700000002",
    name: "Karim",
    schoolCode: "SCH-1",
  });
  // A different school — must not appear in SCH-1's board.
  const other = await register(app, {
    phone: "01700000003",
    name: "Outsider",
    schoolCode: "SCH-2",
  });

  await sync(app, rahim.token, [{ topic: "tense", attempts: 10, correct: 8 }]);
  await sync(app, karim.token, [{ topic: "tense", attempts: 10, correct: 5 }]);
  await sync(app, other.token, [{ topic: "tense", attempts: 10, correct: 9 }]);

  const res = await app.inject({
    method: "GET",
    url: "/leaderboard",
    headers: { authorization: `Bearer ${rahim.token}` },
  });
  const body = res.json();
  assert.equal(body.scoped, true);
  assert.equal(body.week, isoWeek());

  // Only SCH-1 students, ranked by points desc.
  assert.deepEqual(
    body.entries.map((e) => [e.rank, e.name, e.points]),
    [
      [1, "Rahim", 8],
      [2, "Karim", 5],
    ]
  );
  // The caller is flagged and gets their own rank.
  assert.equal(body.entries[0].is_me, true);
  assert.deepEqual(body.me, { rank: 1, points: 8 });

  // Phone numbers are never present in the response.
  assert.ok(!JSON.stringify(body).includes("017000000"));

  await app.close();
  await pool.end();
});

test("further syncs add only the new correct answers to the week", async () => {
  const { app, pool } = await makeTestApp();
  const rahim = await register(app, {
    phone: "01700000001",
    name: "Rahim",
    schoolCode: "SCH-1",
  });
  await sync(app, rahim.token, [{ topic: "tense", attempts: 10, correct: 5 }]);
  // Later cumulative totals: 8 correct now -> +3 this week (total 8).
  await sync(app, rahim.token, [{ topic: "tense", attempts: 12, correct: 8 }]);
  // Re-sending the same totals adds nothing.
  await sync(app, rahim.token, [{ topic: "tense", attempts: 12, correct: 8 }]);

  const res = await app.inject({
    method: "GET",
    url: "/leaderboard",
    headers: { authorization: `Bearer ${rahim.token}` },
  });
  assert.equal(res.json().me.points, 8);
  await app.close();
  await pool.end();
});
