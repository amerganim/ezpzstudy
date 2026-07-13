"use strict";

const crypto = require("crypto");
const { hashPassword } = require("../lib/password");

// Provisioning endpoints for setting up a pilot: create a college, its classes
// (each with a printable enrolment code), teacher accounts, and teacher→class
// assignments. Guarded by a shared admin key (header `x-admin-key`) so no UI is
// needed to onboard the first college. Low-volume, operator-only.

// Human-friendly enrolment code: 6 chars, no ambiguous 0/O/1/I/L.
const CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
function makeEnrollCode() {
  let s = "";
  for (let i = 0; i < 6; i++) {
    s += CODE_ALPHABET[crypto.randomInt(CODE_ALPHABET.length)];
  }
  return s;
}

async function adminRoutes(fastify) {
  // Gate every /admin/* route on the admin key.
  fastify.addHook("preHandler", async (request, reply) => {
    if (!request.url.startsWith("/admin/")) return;
    const key = request.headers["x-admin-key"];
    if (!fastify.config.adminKey || key !== fastify.config.adminKey) {
      return reply.code(401).send({ error: "invalid admin key" });
    }
  });

  fastify.post("/admin/college", async (request, reply) => {
    const b = request.body || {};
    const name = str(b.name);
    if (!name) return reply.code(400).send({ error: "name is required" });
    const id = crypto.randomUUID();
    await fastify.pool.query(
      "INSERT INTO colleges (id, name, district) VALUES ($1, $2, $3)",
      [id, name, str(b.district)]
    );
    return reply.send({ id, name });
  });

  fastify.post("/admin/class", async (request, reply) => {
    const b = request.body || {};
    const collegeId = str(b.college_id);
    const name = str(b.name);
    if (!collegeId || !name) {
      return reply.code(400).send({ error: "college_id and name are required" });
    }
    const college = await fastify.pool.query(
      "SELECT id FROM colleges WHERE id = $1",
      [collegeId]
    );
    if (college.rows.length === 0) {
      return reply.code(404).send({ error: "unknown college" });
    }
    // Retry on the (rare) code collision.
    let id, code;
    for (let attempt = 0; attempt < 5; attempt++) {
      id = crypto.randomUUID();
      code = makeEnrollCode();
      try {
        await fastify.pool.query(
          "INSERT INTO classes (id, college_id, name, enroll_code) VALUES ($1, $2, $3, $4)",
          [id, collegeId, name, code]
        );
        return reply.send({ id, name, enroll_code: code, college_id: collegeId });
      } catch (err) {
        if (attempt === 4) throw err; // give up after retries
      }
    }
  });

  fastify.post("/admin/teacher", async (request, reply) => {
    const b = request.body || {};
    const collegeId = str(b.college_id);
    const phone = str(b.phone);
    const password = typeof b.password === "string" ? b.password : "";
    if (!collegeId || !phone || password.length < 6) {
      return reply
        .code(400)
        .send({ error: "college_id, phone and password (>=6 chars) required" });
    }
    const college = await fastify.pool.query(
      "SELECT id FROM colleges WHERE id = $1",
      [collegeId]
    );
    if (college.rows.length === 0) {
      return reply.code(404).send({ error: "unknown college" });
    }
    const dup = await fastify.pool.query(
      "SELECT id FROM teachers WHERE phone = $1",
      [phone]
    );
    if (dup.rows.length > 0) {
      return reply.code(409).send({ error: "phone already registered" });
    }
    const id = crypto.randomUUID();
    await fastify.pool.query(
      "INSERT INTO teachers (id, college_id, phone, name, pass_hash) VALUES ($1, $2, $3, $4, $5)",
      [id, collegeId, phone, str(b.name), hashPassword(password)]
    );
    return reply.send({ id, phone, name: str(b.name), college_id: collegeId });
  });

  // Assign a teacher to a class (both must be in the same college).
  fastify.post("/admin/assign", async (request, reply) => {
    const b = request.body || {};
    const teacherId = str(b.teacher_id);
    const classId = str(b.class_id);
    if (!teacherId || !classId) {
      return reply.code(400).send({ error: "teacher_id and class_id required" });
    }
    const rows = await fastify.pool.query(
      `SELECT t.college_id AS t_college, c.college_id AS c_college
         FROM teachers t, classes c WHERE t.id = $1 AND c.id = $2`,
      [teacherId, classId]
    );
    if (rows.rows.length === 0) {
      return reply.code(404).send({ error: "unknown teacher or class" });
    }
    if (rows.rows[0].t_college !== rows.rows[0].c_college) {
      return reply.code(400).send({ error: "teacher and class are in different colleges" });
    }
    await fastify.pool.query(
      `INSERT INTO teacher_classes (teacher_id, class_id) VALUES ($1, $2)
         ON CONFLICT DO NOTHING`,
      [teacherId, classId]
    );
    return reply.send({ ok: true });
  });
}

function str(v) {
  return typeof v === "string" && v.trim() ? v.trim() : null;
}

module.exports = { adminRoutes, makeEnrollCode };
