"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { makeTestApp } = require("./helpers/memoryDb");

const ADMIN = { "x-admin-key": "dev-only-admin-key-change-me" };

// Provision a college + class + teacher via the admin endpoints and return ids.
async function provision(app) {
  const college = (
    await app.inject({
      method: "POST",
      url: "/admin/college",
      headers: ADMIN,
      payload: { name: "Test College", district: "Dhaka" },
    })
  ).json();
  const klass = (
    await app.inject({
      method: "POST",
      url: "/admin/class",
      headers: ADMIN,
      payload: { college_id: college.id, name: "HSC 2026 Science A" },
    })
  ).json();
  const teacher = (
    await app.inject({
      method: "POST",
      url: "/admin/teacher",
      headers: ADMIN,
      payload: { college_id: college.id, phone: "01700000000", name: "Mr Rahman", password: "secret123" },
    })
  ).json();
  await app.inject({
    method: "POST",
    url: "/admin/assign",
    headers: ADMIN,
    payload: { teacher_id: teacher.id, class_id: klass.id },
  });
  return { college, klass, teacher };
}

async function teacherLogin(app, phone = "01700000000", password = "secret123") {
  const res = await app.inject({
    method: "POST",
    url: "/teacher/auth",
    payload: { phone, password },
  });
  return res;
}

test("admin endpoints require the admin key", async () => {
  const { app, pool } = await makeTestApp();
  const res = await app.inject({
    method: "POST",
    url: "/admin/college",
    payload: { name: "X" },
  });
  assert.equal(res.statusCode, 401);
  await app.close();
  await pool.end();
});

test("provisioning creates a class with a 6-char enrol code", async () => {
  const { app, pool } = await makeTestApp();
  const { klass } = await provision(app);
  assert.match(klass.enroll_code, /^[A-Z2-9]{6}$/);
  await app.close();
  await pool.end();
});

test("a student joins a class by enrol code and the teacher sees them", async () => {
  const { app, pool } = await makeTestApp();
  const { klass } = await provision(app);

  // Student enrols and syncs some progress.
  const auth = (
    await app.inject({
      method: "POST",
      url: "/auth",
      payload: { phone: "01811111111", name: "Karim", enroll_code: klass.enroll_code },
    })
  ).json();
  assert.equal(auth.student.class_id, klass.id);

  await app.inject({
    method: "POST",
    url: "/sync",
    headers: { authorization: `Bearer ${auth.token}` },
    payload: {
      topic_progress: [{ topic: "tense", attempts: 10, correct: 7 }],
      streak_days: 2,
      sessions: 1,
    },
  });

  // Teacher logs in and reads the class roster.
  const login = (await teacherLogin(app)).json();
  assert.ok(login.token);

  const classes = (
    await app.inject({
      method: "GET",
      url: "/teacher/classes",
      headers: { authorization: `Bearer ${login.token}` },
    })
  ).json();
  assert.equal(classes.classes.length, 1);
  assert.equal(classes.classes[0].student_count, 1);

  const roster = (
    await app.inject({
      method: "GET",
      url: `/teacher/classes/${klass.id}`,
      headers: { authorization: `Bearer ${login.token}` },
    })
  ).json();
  assert.equal(roster.students.length, 1);
  assert.equal(roster.students[0].name, "Karim");
  assert.equal(roster.students[0].attempts, 10);
  assert.equal(roster.students[0].correct, 7);
  assert.equal(roster.students[0].accuracy, 70);
  assert.equal(roster.students[0].weekly_points, 7);

  // Per-student drilldown.
  const drill = (
    await app.inject({
      method: "GET",
      url: `/teacher/students/${auth.student.id}`,
      headers: { authorization: `Bearer ${login.token}` },
    })
  ).json();
  assert.equal(drill.totals.attempts, 10);
  assert.equal(drill.topics[0].topic, "tense");

  await app.close();
  await pool.end();
});

test("wrong teacher password is rejected", async () => {
  const { app, pool } = await makeTestApp();
  await provision(app);
  const res = await teacherLogin(app, "01700000000", "wrongpass");
  assert.equal(res.statusCode, 401);
  await app.close();
  await pool.end();
});

test("a teacher cannot read a class they do not own", async () => {
  const { app, pool } = await makeTestApp();
  const { college, klass } = await provision(app);
  // A second teacher in the same college, NOT assigned to the class.
  const t2 = (
    await app.inject({
      method: "POST",
      url: "/admin/teacher",
      headers: ADMIN,
      payload: { college_id: college.id, phone: "01722222222", name: "Ms X", password: "secret123" },
    })
  ).json();
  const t2login = (await teacherLogin(app, "01722222222")).json();
  const res = await app.inject({
    method: "GET",
    url: `/teacher/classes/${klass.id}`,
    headers: { authorization: `Bearer ${t2login.token}` },
  });
  assert.equal(res.statusCode, 403);
  await app.close();
  await pool.end();
});

test("student and teacher tokens are not interchangeable", async () => {
  const { app, pool } = await makeTestApp();
  const { klass } = await provision(app);
  const studentAuth = (
    await app.inject({
      method: "POST",
      url: "/auth",
      payload: { phone: "01899999999", enroll_code: klass.enroll_code },
    })
  ).json();
  // Student token on a teacher endpoint → 403.
  const asTeacher = await app.inject({
    method: "GET",
    url: "/teacher/classes",
    headers: { authorization: `Bearer ${studentAuth.token}` },
  });
  assert.equal(asTeacher.statusCode, 403);

  // Teacher token on a student endpoint (/sync) → 403.
  const teacherToken = (await teacherLogin(app)).json().token;
  const asStudent = await app.inject({
    method: "POST",
    url: "/sync",
    headers: { authorization: `Bearer ${teacherToken}` },
    payload: { topic_progress: [] },
  });
  assert.equal(asStudent.statusCode, 403);

  await app.close();
  await pool.end();
});

test("an invalid enrol code is rejected", async () => {
  const { app, pool } = await makeTestApp();
  const res = await app.inject({
    method: "POST",
    url: "/auth",
    payload: { phone: "01800000000", enroll_code: "ZZZZZZ" },
  });
  assert.equal(res.statusCode, 404);
  await app.close();
  await pool.end();
});
