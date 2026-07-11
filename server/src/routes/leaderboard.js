"use strict";

const { isoWeek } = require("../lib/week");

// GET /leaderboard — this week's ranking, scoped to the caller's school.
//
// A class/school leaderboard of ~40 peers motivates; a national one demotivates
// a village student. Weekly-resetting so no one is permanently last. Names only
// (or "Student") — phone numbers are never exposed.
const TOP_N = 20;

async function leaderboardRoutes(fastify) {
  fastify.get(
    "/leaderboard",
    { preHandler: fastify.authenticate },
    async (request, reply) => {
      const studentId = request.studentId;
      const me = await fastify.pool.query(
        "SELECT school_code FROM students WHERE id = $1",
        [studentId]
      );
      if (me.rows.length === 0) {
        return reply.code(404).send({ error: "unknown student" });
      }
      const schoolCode = me.rows[0].school_code;
      if (!schoolCode) {
        // Not in a cohort yet — the client nudges the student to add a school code.
        return reply.send({ scoped: false, week: isoWeek(), entries: [], me: null });
      }

      const week = isoWeek();
      const rows = await fastify.pool.query(
        `SELECT s.id, s.name, w.points
           FROM weekly_scores w
           JOIN students s ON s.id = w.student_id
          WHERE s.school_code = $1 AND w.week = $2
          ORDER BY w.points DESC, s.name ASC NULLS LAST, s.id ASC`,
        [schoolCode, week]
      );

      const entries = rows.rows.map((r, i) => ({
        rank: i + 1,
        name: r.name || null,
        points: r.points,
        is_me: r.id === studentId,
      }));

      const mine = entries.find((e) => e.is_me) || null;

      return reply.send({
        scoped: true,
        week,
        entries: entries.slice(0, TOP_N),
        me: mine
          ? { rank: mine.rank, points: mine.points }
          : { rank: null, points: 0 },
      });
    }
  );
}

module.exports = { leaderboardRoutes };
