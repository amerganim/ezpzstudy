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
