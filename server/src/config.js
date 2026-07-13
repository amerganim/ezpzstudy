"use strict";

// Central config, all from the environment so nothing secret is committed.
function loadConfig(env = process.env) {
  return {
    port: parseInt(env.PORT || "8080", 10),
    host: env.HOST || "0.0.0.0",
    databaseUrl:
      env.DATABASE_URL ||
      "postgres://ezpz:ezpz@localhost:5432/ezpzstudy",
    // Secret used to sign auth tokens. MUST be set in production; a fixed
    // dev-only fallback keeps local runs frictionless.
    tokenSecret: env.TOKEN_SECRET || "dev-only-insecure-secret-change-me",
    tokenTtlSeconds: parseInt(env.TOKEN_TTL_SECONDS || "31536000", 10), // 1 year
    // Shared key for the operator-only /admin provisioning endpoints (create
    // colleges/classes/teachers). MUST be set for those routes to work.
    adminKey: env.ADMIN_KEY || "dev-only-admin-key-change-me",
    // Directory holding content packs to serve (local dev; prod serves from R2).
    contentDir: env.CONTENT_DIR || null,
  };
}

module.exports = { loadConfig };
