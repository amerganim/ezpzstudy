# Phase 4 — Teacher Dashboard, Per-College Accounts & College Leaderboards

Status: **planning** (nothing here is built yet). This extends the offline-first
student app into a product a **college can adopt**, where **teachers monitor**
students' practice and run **monitored (cheat-resistant) exams**.

---

## 0. Where we are today (honest baseline)

- **Student app:** offline-first Flutter, all content bundled in the APK.
- **Backend:** Node/Fastify + Postgres, HMAC-token auth, **anonymous
  aggregate-only sync**, plus a **weekly, school-scoped leaderboard**. It runs
  locally only — not hosted yet.
- **Gaps for this phase:** no real identity (students are anonymous), no teacher
  role, no per-student data on the server, no dashboard, no multi-college
  separation.

The big design shift: today sync is deliberately anonymous. Teacher monitoring
**requires per-student identifiable data**, so this phase needs identity,
consent, and access control. That is the main new work.

---

## 1. Platform decision: move the backend to Supabase for the pilot

**Recommendation: build Phase 4 on Supabase**, keeping the app offline-first.

Why: Supabase gives us, out of the box, the four things this phase needs —
hosted **Postgres**, **Auth** (email/password + magic link), **Row-Level
Security (RLS)** for multi-tenant isolation, and auto **REST/Realtime APIs** for
the teacher dashboard. That removes most of the custom-backend work.

- Keep the app's offline-first model: students practice offline, the app syncs
  when a connection is available (matters for village connectivity).
- Free tier is fine for a **1–2 college pilot** (hundreds of students). A real
  multi-college rollout will outgrow it → paid tier or a VPS later.

---

## 2. Data model (multi-tenant: college → class → student/teacher)

```
college(id, name, district, created_at)
class_group(id, college_id, name, exam_year, created_by)         -- "HSC 2026 Science A"
profile(id → auth.users, role, full_name, college_id, class_id)  -- role: student|teacher|college_admin
teacher_class(teacher_id, class_id)                              -- a teacher can own many classes
enrollment_code(code, college_id, class_id, role, expires_at)    -- self-enrolment

practice_session(id, student_id, class_id, mode, started_at, ended_at)   -- mode: practice|exam
practice_attempt(id, session_id, student_id, question_id, topic, difficulty,
                 correct, score, mode, answered_at, time_taken_ms, flags) -- per-attempt = teacher visibility
topic_progress(student_id, topic, attempts, correct, last_practiced)      -- rollup for fast dashboards

assignment(id, class_id, teacher_id, title, topic_set, due_at)            -- "practice these before Friday"
exam(id, class_id, teacher_id, title, topic_set, time_limit_s,
     window_start, window_end, proctored bool)
exam_submission(id, exam_id, student_id, score, started_at, submitted_at, flags)
```

Notes:
- `practice_attempt` is per-attempt so a teacher can see *what* a student did.
  `topic_progress` is the pre-aggregated rollup so dashboards load fast.
- `flags` (jsonb) holds anti-cheat signals: backgrounding events, impossible
  speed, etc.

## 3. Roles & access control (enforced by RLS)

| Role | Can do |
|------|--------|
| **student** | read/write **own** attempts & progress; see **own** class leaderboard |
| **teacher** | read all students in **their** class(es); create assignments/exams; **cannot edit** student attempts |
| **college_admin** | manage classes/teachers, generate enrolment codes, college-wide stats |

RLS policies scope every row by `college_id` / `class_id`, so **College A can
never see College B**, and a teacher only sees their own classes. This is the
core of "per-college accounts."

## 4. Enrolment flow

1. **College admin** creates the college + classes, generates **enrolment codes**
   (or bulk-imports a student roster via CSV).
2. **Teacher** signs up, joins the college with a code, gets assigned class(es).
3. **Student** installs the app, enters a **class enrolment code once** → bound
   to that college + class. Practice still works offline; on login, local
   progress can upload.
4. **Consent:** collect minimal PII (name + class only). Get college/guardian
   consent before storing identified data.

## 5. Teacher dashboard

Two options; recommend shipping **A first, then B**:

- **A. Teacher-lite view inside the same Flutter app (fast to ship).** A role
  switch reveals a "My Classes" screen: student list, weekly activity, accuracy,
  weakest topics, last-active. Good enough to start a pilot.
- **B. Full web dashboard (better for real monitoring).** A small web app
  (Flutter Web or Next.js) on Supabase with teacher auth + RLS. Views:
  - **Class overview:** each student's questions-attempted (week), accuracy,
    streak, weakest topics, last active, predicted board score.
  - **Student drilldown:** topic-by-topic mastery, time spent, trend, flags.
  - **Assign / create exam**, **class & college leaderboard**, **CSV export**.

## 6. Anti-cheat & "monitored practice" — honest scope

**Reality first:** on phones students own, with content bundled offline, you
**cannot guarantee** cheating is impossible. What we *can* build is
**cheat-resistant, anomaly-flagged** sessions. Do not market it as "un-riggable."

- **Practice mode (daily):** light — server-timestamp attempts, flag anomalies
  (impossible speed, app backgrounding), teacher spot-checks. Appropriate and
  enough for low-stakes practice.
- **Exam mode (monitored assessment):**
  - Teacher opens a **timed exam window** for a class.
  - App enters **kiosk/lock** (Android screen pinning), blocks app-switching,
    reports backgrounding to the server.
  - **Randomised** question order per student; **no answer reveal** until submit;
    **one attempt**; **server-authoritative scoring**; **server-enforced** time
    limit; every answer server-timestamped.
  - **Anomaly detection:** impossible speed, backgrounding, duplicate answer
    patterns across students → flagged for the teacher.
  - For **genuinely high-stakes** exams: move exam items **server-side so answer
    keys never ship to the phone**, and require **physical or camera
    invigilation**. State this plainly to colleges.

## 7. College-scoped leaderboard (Feature 1, done right)

- **Scopes:** class → college → (national, opt-in, later).
- **Rank by effort + improvement, not just raw accuracy**, so weak students
  aren't demoralised (the whole point is to help them). Add a **"Most Improved"**
  board alongside the top-scorers board.
- **Anti-gaming:** cap points per topic per day, ignore repeated same-question
  spam, score server-side.
- **Privacy:** display first name + initial or a chosen nickname; visibility
  opt-in.

## 8. Suggested phasing

- **4a — Identity & tenancy:** Supabase migration, auth, the data model above,
  enrolment codes, consent. (Foundation for everything else.)
- **4b — Teacher dashboard:** teacher-lite in-app view, then class/college
  leaderboard, then full web dashboard.
- **4c — Assignments + exam mode:** monitored, cheat-resistant sessions +
  anomaly flags.
- **4d — Close the A+ gap (optional but high-value):** let a teacher **see and
  comment on a student's own writing** (paragraph/letter/essay), since the app's
  writing practice is self-checked today and self-check can't judge real
  composition.

## 9. Cost / hosting

- Supabase free tier → OK for the 1–2 college pilot.
- Keep offline-first so poor village connectivity still works.
- Beyond the pilot, move to Supabase paid or a VPS (matches the earlier
  "prove it, then pay for hosting" strategy).

---

**Before any of this:** get one HSC English teacher to **vet a sample of the
content** (answer keys, Bangla explanations). That is the cheapest,
highest-trust step and is why the current focus is getting the app into a
teacher's hands.
