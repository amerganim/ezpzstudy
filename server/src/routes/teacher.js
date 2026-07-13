"use strict";

const { issueToken } = require("../lib/token");
const { verifyPassword } = require("../lib/password");
const { isoWeek } = require("../lib/week");

// Teacher dashboard API. A teacher logs in with phone + password, then reads
// (never writes) the practice data of students in their own class(es). All
// endpoints scope strictly to classes the teacher owns, so one teacher can
// never see another college's or class's students.
async function teacherRoutes(fastify) {
  // POST /teacher/auth — phone + password → teacher bearer token.
  fastify.post("/teacher/auth", async (request, reply) => {
    const b = request.body || {};
    const phone = typeof b.phone === "string" ? b.phone.trim() : "";
    const password = typeof b.password === "string" ? b.password : "";
    if (!phone || !password) {
      return reply.code(400).send({ error: "phone and password are required" });
    }
    const found = await fastify.pool.query(
      "SELECT * FROM teachers WHERE phone = $1",
      [phone]
    );
    const teacher = found.rows[0];
    if (!teacher || !verifyPassword(password, teacher.pass_hash)) {
      return reply.code(401).send({ error: "invalid phone or password" });
    }
    const token = issueToken(
      teacher.id,
      fastify.config.tokenSecret,
      fastify.config.tokenTtlSeconds,
      Date.now(),
      "teacher"
    );
    return reply.send({
      token,
      teacher: { id: teacher.id, name: teacher.name, phone: teacher.phone },
    });
  });

  // GET /teacher/classes — the teacher's classes with a live student count.
  fastify.get(
    "/teacher/classes",
    { preHandler: fastify.teacherAuthenticate },
    async (request, reply) => {
      const classes = await fastify.pool.query(
        `SELECT c.id, c.name, c.enroll_code, col.name AS college_name
           FROM teacher_classes tc
           JOIN classes c ON c.id = tc.class_id
           JOIN colleges col ON col.id = c.college_id
          WHERE tc.teacher_id = $1
          ORDER BY c.name ASC`,
        [request.teacherId]
      );
      const out = [];
      for (const c of classes.rows) {
        const count = await fastify.pool.query(
          "SELECT COUNT(*)::int AS n FROM students WHERE class_id = $1",
          [c.id]
        );
        out.push({
          id: c.id,
          name: c.name,
          enroll_code: c.enroll_code,
          college_name: c.college_name,
          student_count: count.rows[0].n,
        });
      }
      return reply.send({ classes: out });
    }
  );

  // GET /teacher/classes/:id — the class roster with each student's rollup.
  fastify.get(
    "/teacher/classes/:id",
    { preHandler: fastify.teacherAuthenticate },
    async (request, reply) => {
      const classId = request.params.id;
      if (!(await teacherOwnsClass(fastify, request.teacherId, classId))) {
        return reply.code(403).send({ error: "not your class" });
      }
      const week = isoWeek();

      const roster = await fastify.pool.query(
        `SELECT s.id, s.name, s.last_sync_at,
                COALESCE(SUM(tp.attempts), 0)::int AS attempts,
                COALESCE(SUM(tp.correct), 0)::int  AS correct
           FROM students s
           LEFT JOIN topic_progress tp ON tp.student_id = s.id
          WHERE s.class_id = $1
          GROUP BY s.id, s.name, s.last_sync_at`,
        [classId]
      );
      const pts = await fastify.pool.query(
        `SELECT w.student_id, w.points
           FROM weekly_scores w
           JOIN students s ON s.id = w.student_id
          WHERE s.class_id = $1 AND w.week = $2`,
        [classId, week]
      );
      const pointsById = new Map(pts.rows.map((r) => [r.student_id, r.points]));

      const students = roster.rows
        .map((r) => ({
          id: r.id,
          name: r.name || null,
          attempts: r.attempts,
          correct: r.correct,
          accuracy: r.attempts > 0 ? Math.round((r.correct / r.attempts) * 100) : null,
          weekly_points: pointsById.get(r.id) || 0,
          last_sync_at: r.last_sync_at,
        }))
        .sort(
          (a, b) =>
            b.weekly_points - a.weekly_points ||
            b.attempts - a.attempts ||
            (a.name || "").localeCompare(b.name || "")
        );

      return reply.send({ class_id: classId, week, students });
    }
  );

  // GET /teacher/students/:id — one student's per-topic breakdown.
  fastify.get(
    "/teacher/students/:id",
    { preHandler: fastify.teacherAuthenticate },
    async (request, reply) => {
      const studentId = request.params.id;
      const s = await fastify.pool.query(
        "SELECT id, name, class_id, streak_days, sessions, last_sync_at FROM students WHERE id = $1",
        [studentId]
      );
      if (s.rows.length === 0) {
        return reply.code(404).send({ error: "unknown student" });
      }
      const student = s.rows[0];
      if (
        !student.class_id ||
        !(await teacherOwnsClass(fastify, request.teacherId, student.class_id))
      ) {
        return reply.code(403).send({ error: "not your student" });
      }
      const topics = await fastify.pool.query(
        `SELECT topic, attempts, correct, last_practiced
           FROM topic_progress WHERE student_id = $1
          ORDER BY topic ASC`,
        [studentId]
      );
      const totalAttempts = topics.rows.reduce((n, t) => n + t.attempts, 0);
      const totalCorrect = topics.rows.reduce((n, t) => n + t.correct, 0);
      return reply.send({
        student: {
          id: student.id,
          name: student.name || null,
          streak_days: student.streak_days,
          sessions: student.sessions,
          last_sync_at: student.last_sync_at,
        },
        totals: {
          attempts: totalAttempts,
          correct: totalCorrect,
          accuracy: totalAttempts > 0 ? Math.round((totalCorrect / totalAttempts) * 100) : null,
        },
        topics: topics.rows.map((t) => ({
          topic: t.topic,
          attempts: t.attempts,
          correct: t.correct,
          accuracy: t.attempts > 0 ? Math.round((t.correct / t.attempts) * 100) : null,
          last_practiced: t.last_practiced,
        })),
      });
    }
  );
}

async function teacherOwnsClass(fastify, teacherId, classId) {
  const r = await fastify.pool.query(
    "SELECT 1 FROM teacher_classes WHERE teacher_id = $1 AND class_id = $2",
    [teacherId, classId]
  );
  return r.rows.length > 0;
}

module.exports = { teacherRoutes };
