"use strict";

const { verifyToken } = require("./token");

/**
 * Fastify preHandler that requires a valid bearer token and sets
 * request.studentId. Reply 401 otherwise.
 */
function makeAuthenticate(config) {
  return async function authenticate(request, reply) {
    const payload = readToken(request, config);
    if (!payload) {
      return reply.code(401).send({ error: "invalid or expired token" });
    }
    // Student endpoints reject teacher tokens and vice versa.
    if (payload.role && payload.role !== "student") {
      return reply.code(403).send({ error: "student token required" });
    }
    request.studentId = payload.sub;
  };
}

/**
 * Like [makeAuthenticate] but requires a teacher token; sets request.teacherId.
 */
function makeTeacherAuthenticate(config) {
  return async function teacherAuthenticate(request, reply) {
    const payload = readToken(request, config);
    if (!payload) {
      return reply.code(401).send({ error: "invalid or expired token" });
    }
    if (payload.role !== "teacher") {
      return reply.code(403).send({ error: "teacher token required" });
    }
    request.teacherId = payload.sub;
  };
}

function readToken(request, config) {
  const header = request.headers.authorization || "";
  const match = /^Bearer\s+(.+)$/i.exec(header);
  if (!match) return null;
  return verifyToken(match[1], config.tokenSecret);
}

module.exports = { makeAuthenticate, makeTeacherAuthenticate };
