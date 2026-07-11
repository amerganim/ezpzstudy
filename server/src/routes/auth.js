"use strict";

const crypto = require("crypto");
const { issueToken } = require("../lib/token");

// POST /auth — phone-based find-or-create login, returns a bearer token.
//
// No email, no password (per the master plan: phone number or a school-issued
// code). `phone` is the unique login handle; `name` and `school_code` are
// optional profile/cohort metadata. OTP verification and school-code-only
// login are deliberately deferred until the pilot needs them.
async function authRoutes(fastify) {
  fastify.post("/auth", async (request, reply) => {
    const body = request.body || {};
    const phone = typeof body.phone === "string" ? body.phone.trim() : "";
    if (!phone) {
      return reply.code(400).send({ error: "phone is required" });
    }

    const name = typeof body.name === "string" ? body.name.trim() : null;
    const schoolCode =
      typeof body.school_code === "string" ? body.school_code.trim() : null;

    const pool = fastify.pool;
    const existing = await pool.query(
      "SELECT * FROM students WHERE phone = $1",
      [phone]
    );

    let student;
    if (existing.rows.length > 0) {
      // Update optional metadata if newly provided, but never blank it out.
      const current = existing.rows[0];
      const result = await pool.query(
        `UPDATE students
           SET name = COALESCE($2, name),
               school_code = COALESCE($3, school_code)
         WHERE id = $1
         RETURNING *`,
        [current.id, name, schoolCode]
      );
      student = result.rows[0];
    } else {
      const id = crypto.randomUUID();
      const result = await pool.query(
        `INSERT INTO students (id, phone, name, school_code)
         VALUES ($1, $2, $3, $4)
         RETURNING *`,
        [id, phone, name, schoolCode]
      );
      student = result.rows[0];
    }

    const token = issueToken(
      student.id,
      fastify.config.tokenSecret,
      fastify.config.tokenTtlSeconds
    );

    return reply.send({ token, student: publicStudent(student) });
  });
}

function publicStudent(row) {
  return {
    id: row.id,
    phone: row.phone,
    name: row.name,
    school_code: row.school_code,
    streak_days: row.streak_days,
    sessions: row.sessions,
  };
}

module.exports = { authRoutes, publicStudent };
