"use strict";

const fs = require("fs");
const path = require("path");

const SCHEMA_PATH = path.join(__dirname, "schema.sql");

/**
 * Applies the schema to whatever pool is passed. Idempotent (every statement is
 * CREATE TABLE IF NOT EXISTS), so it is safe to run on every boot.
 */
async function migrate(pool) {
  const sql = fs.readFileSync(SCHEMA_PATH, "utf8");
  await pool.query(sql);
}

// Allow `npm run migrate` to apply against the configured DATABASE_URL.
if (require.main === module) {
  const { loadConfig } = require("../config");
  const { createPool } = require("./pool");
  const pool = createPool(loadConfig().databaseUrl);
  migrate(pool)
    .then(() => {
      // eslint-disable-next-line no-console
      console.log("Schema applied.");
      return pool.end();
    })
    .catch((err) => {
      // eslint-disable-next-line no-console
      console.error("Migration failed:", err);
      process.exit(1);
    });
}

module.exports = { migrate };
