"use strict";

const fs = require("fs");
const path = require("path");

// Content versioning endpoints.
//
//   GET /content/version  -> { latest_version, min_supported_version }
//   GET /content/pack?version=N -> the pack JSON
//
// The app ships the core pack inside the APK, so it never NEEDS this to
// function. /content/version just tells the app whether a newer pack exists.
// In production, packs are served from Cloudflare R2 (free egress) rather than
// the VPS — /content/pack here is for local dev and small pilots; it refuses to
// serve unless CONTENT_DIR is configured.
async function contentRoutes(fastify) {
  fastify.get("/content/version", async (request, reply) => {
    const result = await fastify.pool.query(
      "SELECT version, min_supported FROM content_versions ORDER BY version DESC LIMIT 1"
    );
    if (result.rows.length === 0) {
      // No server-side content registered: the app keeps its bundled pack.
      return reply.send({ latest_version: 0, min_supported_version: 0 });
    }
    const row = result.rows[0];
    return reply.send({
      latest_version: row.version,
      min_supported_version: row.min_supported,
    });
  });

  fastify.get("/content/pack", async (request, reply) => {
    const contentDir = fastify.config.contentDir;
    if (!contentDir) {
      return reply.code(404).send({
        error: "content pack serving is disabled; packs are served from R2",
      });
    }

    let version = parseInt(request.query.version, 10);
    if (!Number.isInteger(version)) {
      const latest = await fastify.pool.query(
        "SELECT version FROM content_versions ORDER BY version DESC LIMIT 1"
      );
      version = latest.rows.length > 0 ? latest.rows[0].version : null;
    }
    if (!Number.isInteger(version)) {
      return reply.code(404).send({ error: "no content version available" });
    }

    // Only ever read a file named for the requested integer version — no path
    // traversal possible.
    const file = path.join(contentDir, `content_pack_v${version}.json`);
    if (!fs.existsSync(file)) {
      return reply.code(404).send({ error: `pack v${version} not found` });
    }
    reply.header("content-type", "application/json");
    return reply.send(fs.readFileSync(file, "utf8"));
  });
}

module.exports = { contentRoutes };
