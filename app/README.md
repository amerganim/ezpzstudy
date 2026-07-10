# EZPZ Study — app

Offline-first Flutter Android app for HSC English practice (Phase 1: the practice engine).
Runs fully offline; the entire question bank ships inside the APK.

## Architecture

```
lib/
  main.dart                 App entry; loads the bundled content pack, then runs the app.
  app_services.dart         Composition root (DB + repositories + scoring), exposed via InheritedWidget.
  data/
    models/                 Parsed question model: envelope + a sealed QuestionData hierarchy (9 types).
    db/                     Drift (local SQLite): questions bank, topic-progress aggregates, SRS state, meta.
    content_loader.dart     Bundled content_pack asset -> SQLite on first run (idempotent, version-guarded).
    question_repository.dart  Rehydrates DB rows into the typed model; builds practice sets.
    progress_repository.dart  Topic-progress aggregates + daily streak + session counting.
    flashcard_repository.dart Builds the SRS due-queue and persists SM-2 results.
  engine/
    scoring/                Pure-Dart scoring: exact / fuzzy (Levenshtein) / accepted-variants / self-check.
    srs/                    Pure-Dart SM-2 spaced repetition.
    session/                SessionController (ChangeNotifier) drives one 10-question session.
  ui/
    home/                   Streak + predicted score + two entry points.
    topics/                 Topic picker.
    session/                Session flow, per-question feedback, summary, and the per-type renderers/.
    flashcards/             SRS review screen.
  l10n/                     Bangla-first UI strings and topic display labels.
  theme/                    One-accent-color, large-tap-target theme.
```

## Content pack

The app consumes `assets/content/content_pack_v1.json`, produced by the Phase 0 pipeline
in `../tools/content-pipeline`. To refresh it after editing content:

```
cd ../tools/content-pipeline
node src/index.js build --input ../../content/samples/sample-questions.xlsx \
  --out ../../content/packs/content_pack_v1.json --pack-version 1
cp ../../content/packs/content_pack_v1.json ../../app/assets/content/content_pack_v1.json
cp ../../content/packs/manifest_v1.json    ../../app/assets/content/manifest_v1.json
```

## Develop

```
flutter pub get
dart run build_runner build        # regenerate Drift code after changing lib/data/db/database.dart
flutter analyze
flutter test                        # engine unit tests + DB round-trip + session widget tests
flutter run                         # on a device/emulator
```
