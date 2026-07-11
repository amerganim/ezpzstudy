# EZPZ Study — server

The deliberately tiny Phase 3 backend. It exists for four things only: auth,
progress sync, content versioning, and (later) pilot analytics. Node + Fastify +
PostgreSQL. No Redis, no GraphQL, no microservices.

## Endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/health` | – | Liveness check |
| POST | `/auth` | – | Phone find-or-create login → bearer token |
| POST | `/sync` | Bearer | Accept an aggregated progress batch (once/twice a day) |
| GET | `/content/version` | – | Latest + minimum-supported content version |
| GET | `/content/pack?version=N` | – | Serve a pack (local dev only; prod uses R2) |

The **sync contract** stores aggregates only — per student, per topic:
`attempts`, `correct`, `last_practiced` — never individual attempts. A few
hundred bytes per student per day is what keeps hosting to ~$6/month.

```
POST /sync   Authorization: Bearer <token>
{
  "since": "2026-07-01T00:00:00Z",
  "topic_progress": [
    { "topic": "narration", "attempts": 60, "correct": 21, "last_practiced": "..." }
  ],
  "streak_days": 12,
  "sessions": 9
}
```

Values are treated as the client's current cumulative totals and upserted
(replace), so re-syncing is idempotent and never loses or double-counts data.

## Run it

**Zero-setup (in-memory, no database):** good for local Flutter development.
Data is not persisted across restarts.

```
npm install
npm run dev:mem        # listens on PORT (default 8080)
```

**Against real Postgres (Docker):**

```
docker compose up -d
cp .env.example .env
npm run migrate
npm start
```

## Test

```
npm test
```

Tests run against an in-memory PostgreSQL (`pg-mem`) with the real schema and the
real app wired on top — so the whole API is exercised end-to-end with no database
infrastructure. Production code targets real Postgres via `pg`.

## Deferred (not in v1, by design)

- OTP / phone verification and school-code-only login (pilot uses phone as the
  login handle)
- Class-scoped weekly leaderboard (Phase 3 stretch)
- Serving content packs from Cloudflare R2 (prod); this server only serves packs
  locally when `CONTENT_DIR` is set
