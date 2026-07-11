"use strict";

// POST /sync — accept a compact batch of AGGREGATED progress, once or twice a
// day per student. Never per-question. This tiny, low-frequency contract is
// what keeps hosting cheap (a few hundred bytes/day/student).
//
// Body (matches the master plan's sync contract):
//   {
//     student_id, since,
//     topic_progress: [{ topic, attempts, correct, last_practiced }],
//     streak_days, sessions
//   }
//
// The token's subject is the authority for whose data this is; a mismatched
// body.student_id is rejected.
async function syncRoutes(fastify) {
  fastify.post(
    "/sync",
    { preHandler: fastify.authenticate },
    async (request, reply) => {
      const body = request.body || {};
      const studentId = request.studentId;

      if (body.student_id && body.student_id !== studentId) {
        return reply
          .code(403)
          .send({ error: "student_id does not match token" });
      }

      const topics = Array.isArray(body.topic_progress)
        ? body.topic_progress
        : [];
      const errors = validateTopics(topics);
      if (errors.length > 0) {
        return reply.code(400).send({ error: "invalid topic_progress", errors });
      }

      const streakDays = safeInt(body.streak_days);
      const sessions = safeInt(body.sessions);

      const client = await fastify.pool.connect();
      try {
        await client.query("BEGIN");

        // The student row must exist (created at /auth). Guard against a token
        // for a since-deleted student.
        const found = await client.query(
          "SELECT id FROM students WHERE id = $1",
          [studentId]
        );
        if (found.rows.length === 0) {
          await client.query("ROLLBACK");
          return reply.code(404).send({ error: "unknown student" });
        }

        for (const t of topics) {
          await client.query(
            `INSERT INTO topic_progress (student_id, topic, attempts, correct, last_practiced)
             VALUES ($1, $2, $3, $4, $5)
             ON CONFLICT (student_id, topic) DO UPDATE
               SET attempts = EXCLUDED.attempts,
                   correct = EXCLUDED.correct,
                   last_practiced = EXCLUDED.last_practiced`,
            [
              studentId,
              t.topic,
              t.attempts,
              t.correct,
              t.last_practiced || null,
            ]
          );
        }

        await client.query(
          `UPDATE students
             SET streak_days = COALESCE($2, streak_days),
                 sessions = COALESCE($3, sessions),
                 last_sync_at = now()
           WHERE id = $1`,
          [studentId, streakDays, sessions]
        );

        await client.query("COMMIT");
      } catch (err) {
        await client.query("ROLLBACK");
        throw err;
      } finally {
        client.release();
      }

      return reply.send({
        ok: true,
        synced_topics: topics.length,
        server_time: new Date().toISOString(),
      });
    }
  );
}

function validateTopics(topics) {
  const errors = [];
  topics.forEach((t, i) => {
    if (!t || typeof t.topic !== "string" || t.topic.trim() === "") {
      errors.push(`topic_progress[${i}].topic must be a non-empty string`);
      return;
    }
    if (!Number.isInteger(t.attempts) || t.attempts < 0) {
      errors.push(`topic_progress[${i}].attempts must be a non-negative integer`);
    }
    if (!Number.isInteger(t.correct) || t.correct < 0) {
      errors.push(`topic_progress[${i}].correct must be a non-negative integer`);
    }
    if (
      Number.isInteger(t.attempts) &&
      Number.isInteger(t.correct) &&
      t.correct > t.attempts
    ) {
      errors.push(`topic_progress[${i}].correct cannot exceed attempts`);
    }
  });
  return errors;
}

function safeInt(v) {
  return Number.isInteger(v) && v >= 0 ? v : null;
}

module.exports = { syncRoutes };
