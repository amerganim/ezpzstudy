# EZPZ Study — PWA (web) build & Vercel deploy

This branch (`pwa`) makes the same Flutter app run as a **Progressive Web App**:
students just open a URL — no APK, no "install unknown apps", no permission
prompts. It still works offline after the first visit and installs to the home
screen ("Add to Home screen").

Everything is the same app as the Android build: same content, same Supabase
backend, same offline-first local database (Drift). Only the *packaging* differs.

## What was needed to make it a PWA

- Added the web platform (`app/web/`): PWA `manifest.json`, icons, a themed
  loading splash in `index.html`.
- **Drift on web** needs its SQLite engine as WebAssembly. Two files live in
  `app/web/` and are loaded at runtime: `sqlite3.wasm` and `drift_worker.js`.
  `AppDatabase` passes them via `DriftWebOptions` (see `lib/data/db/database.dart`).
- **CanvasKit is bundled locally** (`flutter build web --no-web-resources-cdn`)
  instead of fetched from Google's CDN — so it loads on locked-down / slow
  village networks and works fully offline.
- Startup no longer blocks on the network: the local content DB gates startup,
  and `Supabase.initialize()` runs in the background (time-boxed), so a slow or
  unreachable network can never leave the user stuck on the splash.

## Build locally

```bash
cd app
flutter build web --release --no-web-resources-cdn
```

Output is `app/build/web/` — a static site. Serve it with any static server:

```bash
cd app/build/web && python -m http.server 8099
# then open http://localhost:8099
```

## Deploy to Vercel

`vercel.json` (repo root) builds the app on Vercel by cloning the Flutter SDK
and running the web build. Two ways:

**A. Connect the Git repo (easiest, auto-deploys on push)**
1. On vercel.com → **Add New Project** → import this repository.
2. Set the **Production Branch** to `pwa` (Project → Settings → Git).
3. Leave build settings as detected — `vercel.json` already sets the build
   command and output directory (`app/build/web`). Deploy.
4. Vercel gives you a URL like `https://ezpzstudy.vercel.app` — share that.

> The first build clones Flutter and can take a few minutes; later builds are
> faster. If a build times out, use option B.

**B. Build locally, deploy the static output (fastest, most reliable)**
```bash
cd app && flutter build web --release --no-web-resources-cdn
cd build/web && npx vercel deploy --prod
```
This uploads the prebuilt static files — Vercel needs no Flutter SDK.

## Backend

No change from the Android build. The Supabase URL + anon key are baked into
`lib/config/supabase_config.dart`, so the deployed site talks to the same
project. Make sure the Supabase schema is applied and the Anonymous auth
provider is enabled (see `supabase/README.md`).

## Notes

- **Data location:** each student's progress lives in *their browser* (IndexedDB)
  on that device, plus Supabase once they tap "Save progress". Clearing browser
  data wipes the local copy (Supabase copy remains).
- **Install to home screen:** on Android Chrome, students get an "Add to Home
  screen" prompt — it then behaves like an app, full-screen, offline.
- **Updating content:** rebuild and redeploy; the service worker picks up the
  new version on next visit.
