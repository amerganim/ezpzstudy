"use strict";

// Zero-setup dev server: boots the real app on an in-memory pg-mem database and
// listens for HTTP. Lets you run the backend (and point the Flutter app at it)
// with no Docker and no Postgres install — data is not persisted across
// restarts. For anything durable, use `npm start` against real Postgres.
//
//   npm run dev:mem
//
// pg-mem is a devDependency, so this file must never be required by production.
const { newDb } = require("pg-mem");
const { migrate } = require("./db/migrate");
const { buildApp } = require("./app");
const { loadConfig } = require("./config");

async function main() {
  const config = loadConfig();
  const pool = new (newDb().adapters.createPg().Pool)();
  await migrate(pool);

  // Seed a content version so /content/version is meaningful in dev.
  await pool.query(
    "INSERT INTO content_versions (version, min_supported, notes) VALUES (1, 1, 'bundled pack')"
  );

  const app = buildApp({ pool, config, logger: true });
  await app.listen({ port: config.port, host: config.host });
  // eslint-disable-next-line no-console
  console.log(`[dev:mem] in-memory backend listening on ${config.port}`);
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error("dev:mem failed:", err);
  process.exit(1);
});
