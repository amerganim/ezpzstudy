"use strict";

const { newDb } = require("pg-mem");
const { migrate } = require("../../src/db/migrate");
const { buildApp } = require("../../src/app");
const { loadConfig } = require("../../src/config");

// Spins up an in-memory Postgres (pg-mem) with the real schema applied and a
// fully wired app on top — so the whole API is exercised end-to-end without any
// database infrastructure. This is what makes `npm test` runnable anywhere.
async function makeTestApp(overrides = {}) {
  const db = newDb();
  const pgAdapter = db.adapters.createPg();
  const pool = new pgAdapter.Pool();

  await migrate(pool);

  const config = {
    ...loadConfig({}),
    tokenSecret: "test-secret",
    ...overrides.config,
  };

  const app = buildApp({ pool, config });
  await app.ready();

  return { app, pool, db, config };
}

module.exports = { makeTestApp };
