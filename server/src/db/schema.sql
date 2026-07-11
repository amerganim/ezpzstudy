-- EZPZ Study backend schema (Phase 3).
--
-- Critical rule from the master plan: store AGGREGATES, never individual
-- attempts. Per student, per topic: attempts, correct, last_practiced.
-- 5,000 students x ~60 topics = ~300k rows total. Trivial.

CREATE TABLE IF NOT EXISTS students (
  -- App-generated UUID string (portable across Postgres and the pg-mem test DB;
  -- avoids depending on a server-side uuid extension).
  id            text PRIMARY KEY,
  phone         text UNIQUE,
  school_code   text,
  name          text,
  streak_days   integer NOT NULL DEFAULT 0,
  sessions      integer NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now(),
  last_sync_at  timestamptz
);

CREATE TABLE IF NOT EXISTS topic_progress (
  student_id     text NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  topic          text NOT NULL,
  attempts       integer NOT NULL DEFAULT 0,
  correct        integer NOT NULL DEFAULT 0,
  last_practiced timestamptz,
  PRIMARY KEY (student_id, topic)
);

CREATE TABLE IF NOT EXISTS content_versions (
  version       integer PRIMARY KEY,
  min_supported integer NOT NULL DEFAULT 1,
  released_at   timestamptz NOT NULL DEFAULT now(),
  notes         text
);

-- Weekly, school-scoped leaderboard points. One row per student per ISO week;
-- accrued from the correct-answer delta on each sync. Weekly-resetting (a new
-- week starts a new row) so no one is permanently last. Old weeks can be pruned.
CREATE TABLE IF NOT EXISTS weekly_scores (
  student_id text NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  week       text NOT NULL,  -- ISO week, e.g. "2026-W28"
  points     integer NOT NULL DEFAULT 0,
  PRIMARY KEY (student_id, week)
);
