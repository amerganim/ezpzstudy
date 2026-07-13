"use strict";

const crypto = require("crypto");

// Salted scrypt password hashing for teacher accounts. Dependency-free (Node
// built-in), stored as "salt:hash" hex. Teachers get passwords because they
// access a dashboard of students' data; students stay password-free (phone /
// class code) to keep friction low for village users.

function hashPassword(plain) {
  const salt = crypto.randomBytes(16);
  const hash = crypto.scryptSync(String(plain), salt, 32);
  return `${salt.toString("hex")}:${hash.toString("hex")}`;
}

function verifyPassword(plain, stored) {
  if (typeof stored !== "string" || !stored.includes(":")) return false;
  const [saltHex, hashHex] = stored.split(":");
  const salt = Buffer.from(saltHex, "hex");
  const expected = Buffer.from(hashHex, "hex");
  const actual = crypto.scryptSync(String(plain), salt, expected.length);
  return actual.length === expected.length && crypto.timingSafeEqual(actual, expected);
}

module.exports = { hashPassword, verifyPassword };
