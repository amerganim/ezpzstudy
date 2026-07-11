"use strict";

const { Pool } = require("pg");

/**
 * Creates a node-postgres connection pool for the given connection string.
 * In production this points at the pilot's Postgres; tests inject a pg-mem
 * pool instead (see test/helpers/memoryDb.js), so this file is never imported
 * by the test path.
 */
function createPool(databaseUrl) {
  return new Pool({ connectionString: databaseUrl });
}

module.exports = { createPool };
