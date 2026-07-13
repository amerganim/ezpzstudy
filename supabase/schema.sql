-- ─────────────────────────────────────────────────────────────────────────────
-- EZPZ Study — Supabase-native backend (Option B).
--
-- This replaces the Node/Fastify server (which stays on `main`) with pure
-- Postgres running inside Supabase: the same tables, plus all the logic as
-- SECURITY DEFINER functions the app calls via Supabase RPC. No separate app
-- host is needed — Supabase runs everything.
--
-- HOW TO APPLY: open your Supabase project → SQL Editor → paste this whole file
-- → Run. Safe to re-run (idempotent). See supabase/README.md for the full setup.
--
-- AUTH MODEL (per the pilot's needs):
--   • Teachers  = Supabase Auth email + password (free, no SMS).
--   • Students  = Supabase Auth *anonymous* sign-in (free, no phone/OTP cost);
--                 their name is what the teacher sees.
--
-- SECURITY MODEL: Row-Level Security is ON for every table with NO public
-- policies, so the anon/public API key can NOT read/write tables directly.
-- ALL access goes through the SECURITY DEFINER functions below, which enforce
-- "a student only touches their own rows; a teacher only sees their own
-- classes." Provisioning helpers are revoked from clients (operator-only, run
-- from the SQL editor).
-- ─────────────────────────────────────────────────────────────────────────────

create extension if not exists pgcrypto;   -- gen_random_uuid()

-- ── Tables ───────────────────────────────────────────────────────────────────

create table if not exists public.colleges (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  district   text,
  created_at timestamptz not null default now()
);

create table if not exists public.classes (
  id          uuid primary key default gen_random_uuid(),
  college_id  uuid not null references public.colleges(id) on delete cascade,
  name        text not null,
  enroll_code text unique not null,
  created_at  timestamptz not null default now()
);

-- A teacher's id IS their Supabase Auth user id.
create table if not exists public.teachers (
  id         uuid primary key references auth.users(id) on delete cascade,
  college_id uuid references public.colleges(id) on delete set null,
  name       text,
  phone      text,
  created_at timestamptz not null default now()
);

create table if not exists public.teacher_classes (
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  class_id   uuid not null references public.classes(id) on delete cascade,
  primary key (teacher_id, class_id)
);

-- A student's id IS their (anonymous) Supabase Auth user id.
create table if not exists public.students (
  id           uuid primary key references auth.users(id) on delete cascade,
  name         text,
  phone        text,
  class_id     uuid references public.classes(id) on delete set null,
  streak_days  integer not null default 0,
  sessions     integer not null default 0,
  created_at   timestamptz not null default now(),
  last_sync_at timestamptz
);

create table if not exists public.topic_progress (
  student_id     uuid not null references public.students(id) on delete cascade,
  topic          text not null,
  attempts       integer not null default 0,
  correct        integer not null default 0,
  last_practiced timestamptz,
  primary key (student_id, topic)
);

create table if not exists public.weekly_scores (
  student_id uuid not null references public.students(id) on delete cascade,
  week       text not null,          -- ISO week, e.g. "2026-W28"
  points     integer not null default 0,
  primary key (student_id, week)
);

create index if not exists idx_students_class on public.students(class_id);
create index if not exists idx_teacher_classes_teacher on public.teacher_classes(teacher_id);

-- ── Lock everything down: RLS on, no public policies (access via RPC only) ────

alter table public.colleges        enable row level security;
alter table public.classes         enable row level security;
alter table public.teachers        enable row level security;
alter table public.teacher_classes enable row level security;
alter table public.students        enable row level security;
alter table public.topic_progress  enable row level security;
alter table public.weekly_scores   enable row level security;

-- ── Helpers ──────────────────────────────────────────────────────────────────

-- ISO week id matching the Node server (e.g. 2026-W28), in UTC.
create or replace function public.iso_week(ts timestamptz default now())
returns text language sql immutable as $$
  select to_char((ts at time zone 'utc'), 'IYYY"-W"IW');
$$;

-- 6-char enrolment code, avoiding ambiguous 0/O/1/I/L.
create or replace function public.gen_enroll_code()
returns text language plpgsql as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  s text := '';
  i int;
begin
  for i in 1..6 loop
    s := s || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
  end loop;
  return s;
end;
$$;

-- Is the current user a teacher who owns this class?
create or replace function public.owns_class(p_class_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists(
    select 1 from teacher_classes
     where teacher_id = auth.uid() and class_id = p_class_id
  );
$$;

-- ── Student RPCs (callable by any authenticated user) ─────────────────────────

-- Create/update the caller's own student profile (name + phone).
create or replace function public.upsert_student(p_name text, p_phone text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  insert into students(id, name, phone) values (auth.uid(), p_name, p_phone)
  on conflict (id) do update
    set name  = coalesce(nullif(p_name, ''),  students.name),
        phone = coalesce(nullif(p_phone, ''), students.phone);
end;
$$;

-- Join a class by its enrolment code. Returns the class name, or raises if the
-- code is invalid so the app can tell the student to retype it.
create or replace function public.join_class(p_code text)
returns text language plpgsql security definer set search_path = public as $$
declare
  v_class classes%rowtype;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  select * into v_class from classes where enroll_code = upper(trim(p_code));
  if not found then raise exception 'invalid enrolment code' using errcode = 'no_data_found'; end if;
  insert into students(id, class_id) values (auth.uid(), v_class.id)
  on conflict (id) do update set class_id = v_class.id;
  return v_class.name;
end;
$$;

-- Push aggregated progress; accrue this week's leaderboard points from the
-- correct-answer delta. Mirrors the Node /sync contract exactly.
create or replace function public.sync_progress(
  p_topics jsonb, p_streak int, p_sessions int
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_student uuid := auth.uid();
  v_before  int;
  v_after   int;
  v_week    text := iso_week();
  t         jsonb;
  v_att     int;
  v_cor     int;
begin
  if v_student is null then raise exception 'not authenticated'; end if;
  insert into students(id) values (v_student) on conflict (id) do nothing;

  select coalesce(sum(correct), 0) into v_before from topic_progress where student_id = v_student;

  for t in select * from jsonb_array_elements(coalesce(p_topics, '[]'::jsonb)) loop
    v_att := (t->>'attempts')::int;
    v_cor := (t->>'correct')::int;
    if v_att < 0 or v_cor < 0 or v_cor > v_att then
      raise exception 'invalid aggregate for topic %', t->>'topic';
    end if;
    insert into topic_progress(student_id, topic, attempts, correct, last_practiced)
    values (v_student, t->>'topic', v_att, v_cor,
            nullif(t->>'last_practiced', '')::timestamptz)
    on conflict (student_id, topic) do update
      set attempts = excluded.attempts,
          correct = excluded.correct,
          last_practiced = excluded.last_practiced;
  end loop;

  update students
     set streak_days = coalesce(p_streak, streak_days),
         sessions = coalesce(p_sessions, sessions),
         last_sync_at = now()
   where id = v_student;

  select coalesce(sum(correct), 0) into v_after from topic_progress where student_id = v_student;
  if v_after - v_before > 0 then
    insert into weekly_scores(student_id, week, points)
    values (v_student, v_week, v_after - v_before)
    on conflict (student_id, week) do update
      set points = weekly_scores.points + excluded.points;
  end if;
end;
$$;

-- The caller's class weekly leaderboard (names only, self flagged).
create or replace function public.my_leaderboard()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_class uuid;
  v_week  text := iso_week();
  v_entries jsonb;
begin
  select class_id into v_class from students where id = auth.uid();
  if v_class is null then
    return jsonb_build_object('scoped', false, 'week', v_week, 'entries', '[]'::jsonb, 'me', null);
  end if;
  select coalesce(jsonb_agg(row_to_json(r)), '[]'::jsonb) into v_entries from (
    select row_number() over (order by w.points desc, s.name asc nulls last, s.id) as rank,
           s.name, w.points, (s.id = auth.uid()) as is_me
      from weekly_scores w join students s on s.id = w.student_id
     where s.class_id = v_class and w.week = v_week
     order by w.points desc, s.name asc nulls last, s.id
     limit 20
  ) r;
  return jsonb_build_object('scoped', true, 'week', v_week, 'entries', v_entries);
end;
$$;

-- ── Teacher RPCs ──────────────────────────────────────────────────────────────

-- Create/update the caller's teacher profile (first login).
create or replace function public.ensure_teacher(p_name text, p_phone text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  insert into teachers(id, name, phone) values (auth.uid(), p_name, p_phone)
  on conflict (id) do update
    set name  = coalesce(nullif(p_name, ''),  teachers.name),
        phone = coalesce(nullif(p_phone, ''), teachers.phone);
end;
$$;

-- The caller-teacher's classes, each with a live student count.
create or replace function public.my_teacher_classes()
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  return coalesce((
    select jsonb_agg(row_to_json(r)) from (
      select c.id, c.name, c.enroll_code, col.name as college_name,
             (select count(*) from students s where s.class_id = c.id) as student_count
        from teacher_classes tc
        join classes c   on c.id = tc.class_id
        join colleges col on col.id = c.college_id
       where tc.teacher_id = auth.uid()
       order by c.name
    ) r
  ), '[]'::jsonb);
end;
$$;

-- A class roster (only if the caller owns the class).
create or replace function public.teacher_class_roster(p_class_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_week text := iso_week(); v_students jsonb;
begin
  if not owns_class(p_class_id) then raise exception 'not your class'; end if;
  select coalesce(jsonb_agg(row_to_json(r)), '[]'::jsonb) into v_students from (
    select s.id, s.name, s.last_sync_at,
           coalesce(sum(tp.attempts), 0)::int as attempts,
           coalesce(sum(tp.correct), 0)::int  as correct,
           case when coalesce(sum(tp.attempts),0) > 0
                then round(100.0 * sum(tp.correct) / sum(tp.attempts))::int end as accuracy,
           coalesce((select points from weekly_scores w where w.student_id = s.id and w.week = v_week), 0) as weekly_points
      from students s left join topic_progress tp on tp.student_id = s.id
     where s.class_id = p_class_id
     group by s.id, s.name, s.last_sync_at
     order by weekly_points desc, attempts desc, s.name asc nulls last
  ) r;
  return jsonb_build_object('class_id', p_class_id, 'week', v_week, 'students', v_students);
end;
$$;

-- One student's per-topic breakdown (only if the caller owns their class).
create or replace function public.teacher_student_detail(p_student_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_class uuid; v_topics jsonb; v_att int; v_cor int; v_s students%rowtype;
begin
  select * into v_s from students where id = p_student_id;
  if not found then raise exception 'unknown student'; end if;
  if v_s.class_id is null or not owns_class(v_s.class_id) then
    raise exception 'not your student';
  end if;
  select coalesce(sum(attempts),0), coalesce(sum(correct),0) into v_att, v_cor
    from topic_progress where student_id = p_student_id;
  select coalesce(jsonb_agg(row_to_json(r)), '[]'::jsonb) into v_topics from (
    select topic, attempts, correct,
           case when attempts > 0 then round(100.0 * correct / attempts)::int end as accuracy,
           last_practiced
      from topic_progress where student_id = p_student_id order by topic
  ) r;
  return jsonb_build_object(
    'student', jsonb_build_object('id', v_s.id, 'name', v_s.name,
               'streak_days', v_s.streak_days, 'sessions', v_s.sessions,
               'last_sync_at', v_s.last_sync_at),
    'totals', jsonb_build_object('attempts', v_att, 'correct', v_cor,
              'accuracy', case when v_att > 0 then round(100.0 * v_cor / v_att)::int end),
    'topics', v_topics
  );
end;
$$;

-- ── Operator-only provisioning (run from the SQL editor; not the app) ─────────

-- Create (or reuse) a college and add a class; returns {class_id, enroll_code}.
create or replace function public.admin_create_class(p_college_name text, p_class_name text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_college uuid; v_code text; v_class uuid;
begin
  select id into v_college from colleges where name = p_college_name limit 1;
  if v_college is null then
    insert into colleges(name) values (p_college_name) returning id into v_college;
  end if;
  loop
    v_code := gen_enroll_code();
    begin
      insert into classes(college_id, name, enroll_code)
      values (v_college, p_class_name, v_code) returning id into v_class;
      exit;
    exception when unique_violation then
      -- retry on the rare code collision
    end;
  end loop;
  return jsonb_build_object('class_id', v_class, 'enroll_code', v_code, 'college_id', v_college);
end;
$$;

-- Assign a teacher (by their login email) to a class (by its enrol code), and
-- set the teacher's college. The teacher must have signed up in the app first.
create or replace function public.admin_assign_teacher(p_email text, p_enroll_code text)
returns void language plpgsql security definer set search_path = public as $$
declare v_uid uuid; v_class classes%rowtype;
begin
  select id into v_uid from auth.users where email = lower(trim(p_email));
  if v_uid is null then raise exception 'no auth user with email %', p_email; end if;
  select * into v_class from classes where enroll_code = upper(trim(p_enroll_code));
  if not found then raise exception 'no class with code %', p_enroll_code; end if;
  insert into teachers(id, college_id) values (v_uid, v_class.college_id)
  on conflict (id) do update set college_id = excluded.college_id;
  insert into teacher_classes(teacher_id, class_id) values (v_uid, v_class.id)
  on conflict do nothing;
end;
$$;

-- ── Grants: expose client RPCs; keep admin + raw tables off the public API ────

revoke all on function public.admin_create_class(text, text)   from anon, authenticated;
revoke all on function public.admin_assign_teacher(text, text)  from anon, authenticated;

grant execute on function public.upsert_student(text, text)            to authenticated;
grant execute on function public.join_class(text)                      to authenticated;
grant execute on function public.sync_progress(jsonb, int, int)        to authenticated;
grant execute on function public.my_leaderboard()                      to authenticated;
grant execute on function public.ensure_teacher(text, text)            to authenticated;
grant execute on function public.my_teacher_classes()                  to authenticated;
grant execute on function public.teacher_class_roster(uuid)            to authenticated;
grant execute on function public.teacher_student_detail(uuid)          to authenticated;
