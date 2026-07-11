"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { issueToken, verifyToken } = require("../src/lib/token");

const SECRET = "unit-test-secret";

test("a freshly issued token verifies and carries the subject", () => {
  const token = issueToken("student-123", SECRET, 3600);
  const payload = verifyToken(token, SECRET);
  assert.ok(payload);
  assert.equal(payload.sub, "student-123");
});

test("a token signed with a different secret does not verify", () => {
  const token = issueToken("student-123", SECRET, 3600);
  assert.equal(verifyToken(token, "other-secret"), null);
});

test("a tampered payload does not verify", () => {
  const token = issueToken("student-123", SECRET, 3600);
  const [, sig] = token.split(".");
  const forged = `${Buffer.from(JSON.stringify({ sub: "attacker", exp: 9999999999 }))
    .toString("base64")
    .replace(/=+$/, "")}.${sig}`;
  assert.equal(verifyToken(forged, SECRET), null);
});

test("an expired token does not verify", () => {
  const past = Date.now() - 10_000;
  const token = issueToken("student-123", SECRET, 1, past);
  assert.equal(verifyToken(token, SECRET), null);
});

test("garbage input does not verify", () => {
  assert.equal(verifyToken("", SECRET), null);
  assert.equal(verifyToken("no-dot", SECRET), null);
  assert.equal(verifyToken(null, SECRET), null);
});
