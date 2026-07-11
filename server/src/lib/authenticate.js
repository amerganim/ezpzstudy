"use strict";

const { verifyToken } = require("./token");

/**
 * Fastify preHandler that requires a valid bearer token and sets
 * request.studentId. Reply 401 otherwise.
 */
function makeAuthenticate(config) {
  return async function authenticate(request, reply) {
    const header = request.headers.authorization || "";
    const match = /^Bearer\s+(.+)$/i.exec(header);
    if (!match) {
      return reply.code(401).send({ error: "missing bearer token" });
    }
    const payload = verifyToken(match[1], config.tokenSecret);
    if (!payload) {
      return reply.code(401).send({ error: "invalid or expired token" });
    }
    request.studentId = payload.sub;
  };
}

module.exports = { makeAuthenticate };
