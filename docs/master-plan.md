# EZPZ Study — Master Build Plan
### Offline-first Android English practice app for Bangladesh (HSC-first)
### Pilot: 1–2 years, village school/college → then market launch

---

## Part 1 — Product Philosophy

**One job for v1:** get a weak student from failing to passing English 1st & 2nd Paper, and get a decent student from passing to good marks.

Everything that doesn't serve that job gets deferred. No teacher features, no AI, no video, no social feed in v1. Those come after the pilot proves the core works.

**The three student truths this app is built around:**

1. **They fail from lack of repetition, not lack of intelligence.** So the app must make repetition frictionless and fast — a student should be answering their first question within 5 seconds of opening the app.
2. **They are ashamed of weak basics.** So remediation must never be labeled as lower-class content. A class 11 student practicing class 8 tenses sees "Focus Area: Tense," never "Class 8."
3. **They are motivated by marks, not by learning.** So every screen speaks in the language of exams: "This topic is worth 10 marks in your board exam," "You'd score 6/10 on this section today." Not "You've mastered 60% of the tense module."

---

## Part 2 — Making It Affordable, Usable, Attractive & Engaging

### Affordable
- **Free during the entire pilot.** Charging during a 1–2 year experiment corrupts your data and kills adoption in a village school.
- App must run on a **low-end Android phone** (2GB RAM, Android 8+) and work with **zero internet** after install. Data cost is a real barrier — treat every megabyte as money out of a student's pocket.
- Keep APK small (target under 40MB). Ship the core content pack inside the APK so the student never pays data to download questions.
- Later monetization (post-pilot, not now): free core + paid mock-test/premium content, or school licensing. Do not build payments in v1.

### Easy to use
- **No email signup.** Phone number or a school-issued code. Many students have no email and abandoned signups kill funnels.
- **Bangla-first UI, English content.** Instructions, rule explanations, and buttons in Bangla; the English being practiced stays English. This is the single biggest usability decision for weak students.
- **Maximum 3 taps from app-open to answering a question.** Home → Topic → Practice.
- Large tap targets, high contrast, works one-handed. Assume a cracked screen and a slow phone.
- Every wrong answer immediately shows the correct answer **plus a one-line rule explanation in Bangla.** Never just "Wrong."

### Attractive
- Clean, modern, uncluttered. Avoid the cheap "coaching center poster" look — students respond to apps that feel like the apps they already use.
- One strong accent color, generous whitespace, a readable Bangla font (e.g. a well-chosen Noto/Hind Siliguri variant) and a clean English font.
- Instant, satisfying feedback animation on a correct answer. Small thing, huge retention effect.

### Engaging (the retention engine)
Engagement is where most education apps die. Build these four, in this order of importance:

1. **Daily streak.** The single most powerful retention mechanic ever built. "You've practiced 12 days in a row." Show it on the home screen. Make breaking it feel bad.
2. **Marks-framed progress.** A visible "Predicted Board Score" that rises as accuracy improves across weighted topics. This is your killer feature — it directly answers "will I pass?" Weight it by real board mark distribution so it's honest.
3. **Focus Areas.** Auto-surfaced weak topics: "You miss 7 out of 10 Narration questions. Practice now." Removes the burden of deciding what to study, which is exactly what weak students can't do.
4. **Leaderboard, scoped to their own school/class.** A national leaderboard demotivates a village student. A class leaderboard of 40 peers motivates fiercely. Make it opt-in-visible, weekly-resetting so no one is permanently last.

**Deliberately avoid:** lives/hearts that block practice (punishes the weak students you're trying to save), and gems/currency systems (adds complexity, no learning value).

---

## Part 3 — Technical Architecture

### Client (the real product)
- **Flutter**, single codebase, Android first. Web/iOS possible later at low marginal cost.
- **Local SQLite** (via Drift) holds the entire question bank and all progress. The app is fully functional with the phone in airplane mode.
- **Client-side scoring engine** — pure Dart, no network:
  - Exact match: MCQ, matching, rearranging
  - Fuzzy match (Levenshtein distance ≤ 1–2): fill-in-blank, to forgive typos and spelling slips
  - Accepted-variants list: grammar transformations (voice/narration often have 2–3 valid forms)
  - Self-check: writing tasks (student writes → reveals model answer + rubric checklist → self-scores)
- **Spaced repetition** for vocabulary flashcards (a simple SM-2 style interval algorithm, all local). Cheap to build, disproportionate learning gain.

### Backend (deliberately tiny)
The server exists for **four things only**. Nothing else.

1. **Auth** — phone/school-code login, issue a token.
2. **Progress sync** — accept a batch of aggregated progress, once or twice a day. Never per-question.
3. **Content pack updates** — tell the app "content version 7 is available," serve the diff.
4. **Pilot analytics** — anonymous aggregate stats you need to measure whether this works.

**Stack recommendation:**
- **Node.js + Fastify** (or Django if your team prefers Python — both are fine; pick what your developer already knows, this is not a place to learn a new language)
- **PostgreSQL** for users, progress aggregates, content versions
- **Redis** — skip it entirely in v1. You don't have the traffic. Add only if measurements demand it.
- REST API, JSON, token auth. No GraphQL, no microservices, no Kubernetes. Resist all of it.

### The sync contract (this is what keeps hosting cheap)
The app never asks the server for a question. It only ever sends a compact summary:

```
POST /sync
{
  "student_id": "...",
  "since": "2026-07-01T00:00:00Z",
  "topic_progress": [
    {"topic": "narration", "attempts": 60, "correct": 21, "last_practiced": "..."},
    {"topic": "tense", "attempts": 40, "correct": 33, "last_practiced": "..."}
  ],
  "streak_days": 12,
  "sessions": 9
}
```
A few hundred bytes, once a day, per student. 5,000 students = ~3–4 requests/minute average. This is why a small VPS is enough.

**Critical schema rule:** store *aggregates*, never individual attempts. Per student, per topic: attempts, correct, last_practiced. 5,000 students × ~60 topics = 300,000 rows total. Trivial. Storing every attempt would be tens of millions of rows and would eventually cost you real money.

### Hosting
| Stage | Setup | Rough cost |
|---|---|---|
| **Pilot (30–500 students)** | Single VPS, 1GB RAM (DigitalOcean/Hetzner/Linode), Postgres on the same box, Caddy or Nginx for TLS | ~$5–6/month |
| **Post-pilot (5,000+)** | Same VPS, maybe bumped to 2GB. Content packs moved to **Cloudflare R2** (free egress) | ~$6–12/month + near-zero CDN |
| **Domain** | www.ezpzstudy.com | ~1,500 Tk/year |

Use a **VPS, not shared cPanel hosting.** Shared hosting's concurrent-process limits (often ~20–25) will 508-error on you unpredictably, and you can't run a proper Node/Postgres process on most of them. The price difference is negligible; the operational difference is large.

Backups: nightly `pg_dump` to Cloudflare R2 or Backblaze B2. A pilot's data is 2 years of irreplaceable research — losing it loses the whole exercise.

Do **not** put content packs on your VPS bandwidth. 5,000 students × 100MB = 500GB of egress, which will get you throttled or billed. Ship content in the APK, serve updates from R2.

---

## Part 4 — Phase-by-Phase Plan

### Phase 0 — Foundations (Weeks 1–3) — *no app code*
- Lock the **question-type schema** (JSON/SQLite) covering: flashcard, MCQ, fill-in (word bank), fill-in (open), matching, rearranging, grammar transformation, comprehension set, writing prompt + model answer.
- Build the **HSC topic map**, weighted by real board mark distribution — plus the remedial SSC-level topics that feed into each.
- Recruit **2–3 English teachers**, including one from the pilot school. They validate the schema and later write items. This is the highest-leverage hire in the whole project.
- Set up a **content authoring spreadsheet** that exports directly to your schema. Teachers write in Google Sheets; a script converts to the content pack. Never make teachers touch a CMS.

**Exit criteria:** a teacher can write 20 questions in the spreadsheet and a script turns them into a valid content pack.

---

### Phase 1 — Practice Engine (Weeks 4–10)
Build the app with dummy content. The engine, not the content, is the product.

- Flutter app shell, Bangla-first UI
- Local SQLite content store + progress store
- Question renderer that handles every type from Phase 0 generically
- Client-side scoring engine (exact / fuzzy / variants / self-check)
- Session flow: pick topic → 10-question set → instant feedback per question → session summary
- Spaced-repetition flashcard module

**Runs entirely offline. No server exists yet.**

**Exit criteria:** you can hand the APK to a student with a content pack and they can practice for an hour, offline, and get scored.

---

### Phase 2 — Diagnostic, Focus Areas & Engagement (Weeks 11–16)
- **HSC Readiness Check**: ~25–30 item diagnostic spanning SSC fundamentals + HSC skills. Framed as exam readiness, never as "lower class."
- Routing algorithm → generates each student's Focus Areas queue from diagnostic + ongoing accuracy.
- **Predicted Board Score** (weighted by real mark distribution).
- **Daily streak** + session summary + weekly local progress view.
- Strong-student track: once Focus Areas are cleared, unlock harder "Challenge" sets and full-length practice.

**Exit criteria:** two students with different diagnostic results get visibly different practice queues, and both see their predicted score move after a week of practice.

---

### Phase 3 — Minimal Backend + Sync (Weeks 17–22)
- VPS provisioned, domain live at www.ezpzstudy.com, TLS via Caddy/Let's Encrypt
- Node/Fastify + Postgres. Endpoints: `/auth`, `/sync`, `/content/version`, `/content/pack`
- Phone/school-code auth
- Aggregated daily progress sync, offline queue with retry (village internet is intermittent — sync must never lose data or block practice)
- Nightly automated Postgres backups off-site
- Class-scoped weekly leaderboard (server-computed, cheap)

**Exit criteria:** a student practices offline for 3 days, connects to internet once, and all progress lands on the server correctly.

---

### Phase 4 — Content Production (runs in parallel from Week 4 onward)
Teachers write; you review and import. Priority order:

1. **Grammar drill sets** (2nd Paper) — highest marks-per-effort, 100% auto-gradable: tense, right form of verbs, subject-verb agreement, voice, narration, prepositions, connectors, tag questions, transformation of sentences, punctuation
2. **Vocabulary flashcard decks** — high-frequency HSC words: Bangla meaning, example sentence, synonym/antonym
3. **Comprehension sets** (1st Paper) — original passages (do not copy board papers verbatim; write in the same style) with MCQ/fill-in/matching/True-False
4. **Writing practice** — application, formal/informal letter, email, paragraph, essay, dialogue, report, CV — each with a model answer and a self-check rubric checklist
5. **Diagnostic bank** + full-length timed mock papers

**Volume target for pilot launch:** ~3,000–5,000 items. Enough that no student exhausts the bank in 2 years.

---

### Phase 5 — Pilot Launch & Measurement (Month 7 → Month 24)

This is a **research project**, not a soft launch. Design it so the results are credible to a school, an investor, or a ministry.

**Setup:**
- One village school/college, class 11–12. Target 100–200 students if possible.
- **Baseline everything before rollout:** the HSC Readiness Check, plus each student's most recent real English exam marks.
- Ideally keep a **comparison group** — another section or a similar nearby school that doesn't use the app. Without this you can't distinguish your app's effect from students simply maturing over a year. This one decision is what makes your eventual marketing claim defensible.

**Track continuously:**
- Weekly active students, streak retention (what % still practicing at week 4, 12, 26 — expect steep drop-off; that's normal, and improving it is the real work)
- Topic-level accuracy over time
- Predicted score vs. actual school exam marks (calibrate your prediction model against reality)
- **The headline metric: English pass rate and average marks, app users vs. comparison group.**

**Cadence:**
- Month 7–9: launch, fix the flood of usability problems that only real students reveal
- Month 10–15: content expansion based on where students actually struggle; retention experiments
- Month 16–24: hold steady, collect the full-year exam outcomes, write up results

**What you'll almost certainly discover (plan for it):**
- Retention collapses in weeks 2–4. Fixing this is more important than any new feature.
- Students misuse the self-check writing module (marking themselves correct when they're not). Consider requiring the checklist before revealing the model answer.
- Some phones are too slow or too full to install. Keep the APK small.
- The teachers become your best distribution channel long before you build teacher features.

---

### Phase 6 — Post-Pilot (Year 2+)
Only after the pilot data is in:
- Expand content down to classes 1–10 (your original full vision)
- **Teacher–student platform**: teacher assigns practice sets, sees class-wide weak topics, tracks individual students. Your pilot teachers will have told you exactly what they need by then — build from their words, not from guesses.
- Revisit AI writing feedback as a premium tier, now justified by real usage data and real revenue
- Marketing, powered by a real number: *"Students using EZPZ Study improved English marks by N% over one year."*

---

## Part 5 — What to Resist

Every failed education app died of one of these. Write them on a wall:

- Building teacher features before proving student outcomes
- Adding video lessons (expensive to make, expensive to host, low completion rates, and YouTube already exists)
- A server-rendered web app (destroys the cost model)
- Storing every question attempt in the database
- Shared cPanel hosting
- Charging money during the pilot
- Launching to 5,000 students before 100 students have used it for 6 months
- Any feature that blocks a struggling student from practicing more

---

## Summary Timeline

| Months | Phase | Server needed? |
|---|---|---|
| 0–1 | Schema, topic map, teacher recruitment | No |
| 1–3 | Practice engine (offline app) | No |
| 3–4 | Diagnostic, Focus Areas, engagement | No |
| 4–6 | Minimal backend, sync, hosting live | Yes (~$6/mo) |
| 1–6 (parallel) | Content production | No |
| 7–24 | Pilot + measurement at village school | Yes (same box) |
| 24+ | Teacher platform, class 1–10, monetization, marketing | Scales |

Total infrastructure cost through the entire pilot: roughly **10,000–15,000 Taka per year**, dominated by the domain and one small VPS. The real cost of this project is the content and the teachers' time — which is exactly as it should be.
