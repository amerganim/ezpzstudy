"use strict";

const { loadConfig } = require("./config");
const { createPool } = require("./db/pool");
const { migrate } = require("./db/migrate");
const { buildApp } = require("./app");

// Real entry point: connect to Postgres, apply the schema, and listen.
async function main() {
  const config = loadConfig();
  const pool = createPool(config.databaseUrl);

  await migrate(pool);

  const app = buildApp({ pool, config, logger: true });

  const shutdown = async () => {
    await app.close();
    await pool.end();
    process.exit(0);
  };
  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);

  await app.listen({ port: config.port, host: config.host });
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error("Failed to start server:", err);
  process.exit(1);
});
