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

    // Optional: join a college class via an enrolment code. An invalid code is
    // rejected so the student knows to retype it, rather than silently ignored.
    const enrollCode =
      typeof body.enroll_code === "string" ? body.enroll_code.trim().toUpperCase() : "";
    let classId = null;
    if (enrollCode) {
      const cls = await pool.query(
        "SELECT id FROM classes WHERE enroll_code = $1",
        [enrollCode]
      );
      if (cls.rows.length === 0) {
        return reply.code(404).send({ error: "invalid enrolment code" });
      }
      classId = cls.rows[0].id;
    }

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
               school_code = COALESCE($3, school_code),
               class_id = COALESCE($4, class_id)
         WHERE id = $1
         RETURNING *`,
        [current.id, name, schoolCode, classId]
      );
      student = result.rows[0];
    } else {
      const id = crypto.randomUUID();
      const result = await pool.query(
        `INSERT INTO students (id, phone, name, school_code, class_id)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [id, phone, name, schoolCode, classId]
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
    class_id: row.class_id,
    streak_days: row.streak_days,
    sessions: row.sessions,
  };
}

module.exports = { authRoutes, publicStudent };
