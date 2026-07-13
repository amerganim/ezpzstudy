"use strict";

const Fastify = require("fastify");
const { makeAuthenticate, makeTeacherAuthenticate } = require("./lib/authenticate");
const { authRoutes } = require("./routes/auth");
const { syncRoutes } = require("./routes/sync");
const { contentRoutes } = require("./routes/content");
const { leaderboardRoutes } = require("./routes/leaderboard");
const { teacherRoutes } = require("./routes/teacher");
const { adminRoutes } = require("./routes/admin");

/**
 * Builds the Fastify app over injected dependencies. Does NOT listen — callers
 * (server.js for real, tests for pg-mem) own the lifecycle. Keeping the pool
 * and config injected is what lets the whole API be tested in-memory.
 *
 * @param {{ pool: import('pg').Pool, config: object, logger?: boolean }} deps
 */
function buildApp({ pool, config, logger = false }) {
  const fastify = Fastify({ logger });

  fastify.decorate("pool", pool);
  fastify.decorate("config", config);
  fastify.decorate("authenticate", makeAuthenticate(config));
  fastify.decorate("teacherAuthenticate", makeTeacherAuthenticate(config));

  fastify.get("/health", async () => ({ ok: true }));

  fastify.register(authRoutes);
  fastify.register(syncRoutes);
  fastify.register(contentRoutes);
  fastify.register(leaderboardRoutes);
  fastify.register(teacherRoutes);
  fastify.register(adminRoutes);

  return fastify;
}

module.exports = { buildApp };
