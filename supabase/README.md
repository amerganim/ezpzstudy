# EZPZ Study — Supabase backend (Option B)

This is the **all-in-Supabase** version of the backend, on the `supabase-native`
branch. `main` keeps the Node/Fastify server untouched. Here, Supabase runs
everything — the database **and** the logic (as SQL functions the app calls).
No second server/host is needed.

## What it is

- `schema.sql` — the whole backend: tables (colleges, classes, teachers,
  students, topic_progress, weekly_scores) + all logic as SECURITY DEFINER
  functions (join a class, sync progress, leaderboard, teacher roster & student
  drilldown) + provisioning helpers.
- Row-Level Security is ON with no public policies, so the app's public key
  **cannot touch tables directly** — every action goes through a function that
  enforces "a student only touches their own data; a teacher only sees their own
  classes."

## Auth model (chosen for a village pilot — no SMS costs)

- **Teachers:** Supabase Auth **email + password**.
- **Students:** Supabase **anonymous** sign-in (free, no phone/OTP). The name a
  student types is what the teacher sees; progress is tied to the device's
  anonymous account.

## One-time setup (≈5 minutes, all in the Supabase dashboard)

1. **Apply the schema.** SQL Editor → paste all of `schema.sql` → **Run**.
2. **Enable anonymous sign-ins.** Authentication → Providers → **Anonymous** →
   enable.
3. **Ease teacher signup for the pilot.** Authentication → Providers → Email →
   turn **"Confirm email" OFF** (so a teacher can log in immediately without an
   email link). You can turn it back on later.
4. **Create your first class.** SQL Editor → run:
   ```sql
   select admin_create_class('Demo College', 'HSC 2026 Science A');
   ```
   It returns an `enroll_code` (e.g. `262MRS`) — that's what students type to join.
5. **Onboard the teacher.** The teacher installs the app, taps "I'm a teacher",
   and **signs up** with their email + a password. Then you link them to the
   class (SQL Editor):
   ```sql
   select admin_assign_teacher('teacher@example.com', '262MRS');
   ```

That's it — students enter the enrol code, practice, and their progress shows up
on the teacher's dashboard.

## What Claude needs from you to finish the app

To build the APK that talks to your project, I need the **two public values**
(safe to embed in a mobile app — they are not secrets; RLS protects your data):

- **Project URL** — Settings → API → *Project URL*
  (looks like `https://abcdxyz.supabase.co`).
- **anon / publishable key** — Settings → API → *Project API keys* → `anon`.

**Keep secret (do NOT share):** the `service_role` key and the database password.

Once you paste those two values to me, I'll wire the app, build a release APK
pointed at your Supabase project, and we test the full teacher/student loop on
your phone.

## Handy operator queries

```sql
-- see all classes and their codes
select c.name, c.enroll_code, col.name as college from classes c join colleges col on col.id = c.college_id;

-- see a class's students and totals
select s.name, sum(tp.attempts) attempts, sum(tp.correct) correct
from students s left join topic_progress tp on tp.student_id = s.id
where s.class_id = (select id from classes where enroll_code = '262MRS')
group by s.name;
```
