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
  -- Phase 4: a student may join a college class via an enrolment code. When
  -- set, their (aggregate) progress becomes visible to that class's teacher and
  -- the leaderboard is scoped to the class. Nullable — the app works fully
  -- without ever joining a class.
  class_id      text,
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

-- ── Phase 4: colleges, classes, teachers ──────────────────────────────────────
-- A college adopts the app; it has classes; each class has a teacher and an
-- enrolment code students type once to join. Kept deliberately small — a pilot
-- has a handful of colleges and classes.

CREATE TABLE IF NOT EXISTS colleges (
  id          text PRIMARY KEY,
  name        text NOT NULL,
  district    text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS classes (
  id          text PRIMARY KEY,
  college_id  text NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
  name        text NOT NULL,                 -- e.g. "HSC 2026 Science A"
  enroll_code text UNIQUE NOT NULL,          -- students enter this to join
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS teachers (
  id          text PRIMARY KEY,
  college_id  text NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
  phone       text UNIQUE NOT NULL,          -- login handle
  name        text,
  pass_hash   text NOT NULL,                 -- salted scrypt hash (see lib/password.js)
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- A teacher can own several classes.
CREATE TABLE IF NOT EXISTS teacher_classes (
  teacher_id  text NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
  class_id    text NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  PRIMARY KEY (teacher_id, class_id)
);
