"use strict";

const crypto = require("crypto");

// Compact HMAC-signed tokens: base64url(payload) "." base64url(HMAC-SHA256).
// A tiny, dependency-free stand-in for JWT — enough for a pilot's token auth,
// and easy to swap for a library later if the backend ever needs more.

function base64url(buf) {
  return Buffer.from(buf)
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function fromBase64url(str) {
  const pad = str.length % 4 === 0 ? "" : "=".repeat(4 - (str.length % 4));
  return Buffer.from(str.replace(/-/g, "+").replace(/_/g, "/") + pad, "base64");
}

function sign(payloadPart, secret) {
  return base64url(
    crypto.createHmac("sha256", secret).update(payloadPart).digest()
  );
}

/**
 * Issues a token for subject [sub], valid for [ttlSeconds]. [role] defaults to
 * "student"; teacher tokens carry role "teacher" so one preHandler can tell
 * them apart.
 */
function issueToken(sub, secret, ttlSeconds, now = Date.now(), role = "student") {
  const iat = Math.floor(now / 1000);
  const payload = { sub, role, iat, exp: iat + ttlSeconds };
  const payloadPart = base64url(JSON.stringify(payload));
  return `${payloadPart}.${sign(payloadPart, secret)}`;
}

/**
 * Verifies a token. Returns the payload if valid and unexpired, else null.
 * Uses a constant-time comparison on the signature.
 */
function verifyToken(token, secret, now = Date.now()) {
  if (typeof token !== "string" || !token.includes(".")) return null;
  const [payloadPart, signature] = token.split(".");
  if (!payloadPart || !signature) return null;

  const expected = sign(payloadPart, secret);
  const a = Buffer.from(signature);
  const b = Buffer.from(expected);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return null;

  let payload;
  try {
    payload = JSON.parse(fromBase64url(payloadPart).toString("utf8"));
  } catch {
    return null;
  }
  if (!payload || typeof payload.sub !== "string") return null;
  if (typeof payload.exp !== "number" || payload.exp < Math.floor(now / 1000)) {
    return null;
  }
  return payload;
}

module.exports = { issueToken, verifyToken };
