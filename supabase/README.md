# EZPZ Study — Supabase backend (Option B, pilot-simple)

This is the **all-in-Supabase** backend, on the `supabase-native` branch. `main`
keeps the Node/Fastify server untouched. Here, Supabase runs everything — the
database **and** the logic (as SQL functions the app calls). No second host.

## What it is

- `schema.sql` — the whole backend: tables + all logic as SECURITY DEFINER
  functions the app calls via Supabase RPC.
- Row-Level Security is ON with no public table policies, so the app's public
  key **cannot touch tables directly** — every action goes through a function.

## The pilot model (deliberately simple)

- **Practice needs no account.** Anyone installs and practises offline forever.
- **"Save my progress"** signs the device in *anonymously* (free, no SMS/OTP) and
  stores the student's **name + phone**. Their progress is saved under that name
  and powers the weekly leaderboard.
- **No teacher login.** Anyone (teacher, parent) taps **"সব শিক্ষার্থীর অগ্রগতি
  দেখো"** (See all students' progress) and sees every student's rollup and
  per-topic breakdown — **without any account**. This is served by the
  `public_roster` / `public_student_detail` functions, which are granted to the
  anonymous public role on purpose.

  > Trade-off: the public view exposes student **phone numbers**. That's fine for
  > a small, trusted pilot; lock it down before any wider release.

## One-time setup (≈2 minutes, all in the Supabase dashboard)

1. **Apply the schema.** SQL Editor → paste all of `schema.sql` → **Run**.
   (Safe to re-run — it's idempotent, so applying an updated `schema.sql` over an
   old one updates the functions in place without touching data.)
2. **Enable anonymous sign-ins.** Authentication → Providers → **Anonymous** →
   enable. *(This is the only provider the pilot needs — no email/password.)*

That's it. Ship the APK; students save their name + phone, and anyone can view
everyone's progress from inside the app.

## What Claude needs from you to build the app

The **two public values** (safe to embed in a mobile app — not secrets; RLS
protects your data), already wired into this build:

- **Project URL** — Settings → API → *Project URL*.
- **anon / publishable key** — Settings → API → *Project API keys* → `anon`.

**Keep secret (never share):** the `service_role` key and the database password.

## Handy operator queries

```sql
-- everyone and their totals
select s.name, s.phone, s.last_sync_at,
       coalesce(sum(tp.attempts),0) attempts, coalesce(sum(tp.correct),0) correct
from students s left join topic_progress tp on tp.student_id = s.id
group by s.id, s.name, s.phone, s.last_sync_at
order by attempts desc;
```

## Note on the leftover class/teacher tables

`schema.sql` still contains the `colleges` / `classes` / `teachers` tables and
their functions from the earlier design. They're unused by the pilot app but left
in place (harmless) in case per-college scoping is wanted later. The app talks
only to: `upsert_student`, `sync_progress`, `my_leaderboard`, `public_roster`,
and `public_student_detail`.
