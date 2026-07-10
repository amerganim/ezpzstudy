# Content schema

`question-schema.json` and `content-pack-schema.json` are the canonical, language-agnostic
contract for a single question and for a whole content pack. They're JSON Schema
(2020-12), validated with `ajv` in `tools/content-pipeline`. Every future consumer
(Flutter/Drift in Phase 1, Postgres/Fastify in Phase 3) is expected to agree with this
shape rather than inventing its own.

## Envelope + `data`

Every question is an **envelope** (fields common to all 9 types) wrapping a **`data`**
blob whose shape depends on `type`. This maps directly onto a future Drift table
(envelope fields = typed columns, `data` = one JSON/TEXT column) and a future Postgres
table (typed columns + `jsonb data`) without restructuring.

| Field | Notes |
|---|---|
| `id` | Global id: `{paper_code}.{type}.{teacher_id}`, e.g. `p2.mcq.tense-01`. Namespaced by the build script from the teacher's short spreadsheet id. |
| `type` | One of the 9 question types (see below). |
| `paper` | `1st` or `2nd`. |
| `topic` / `subtopic` | Must resolve against `content/topic-map/topic-map.yaml`. |
| `difficulty` | `easy` / `medium` / `hard`. |
| `marks_weight` | Number > 0. Feeds the Phase 2 "Predicted Board Score." |
| `tags` | Free-form array, e.g. `["exam-common"]`. |
| `instruction_bn` | Short Bangla instruction shown before the question. UI stays Bangla-first; `data` stays English. |
| `explanation_bn` | One-line Bangla rule explanation shown on a wrong answer. Required by product philosophy -- never just "Wrong." |
| `review_status` | `draft` / `reviewed` / `published`. Lightweight QA gate; the build script can filter to `published` only. No CMS needed. |
| `author` | Free-text credit, e.g. a teacher's name or `dev-sample` for proof-run content. |
| `data` | Type-specific fields, see `question-schema.json`'s `$defs`. |

`additionalProperties: false` is set everywhere so a stray/typo'd column errors instead
of silently vanishing from the pack.

## The 9 question types

`flashcard`, `mcq`, `fill_in_word_bank`, `fill_in_open`, `matching`, `rearranging`,
`grammar_transformation`, `comprehension_set`, `writing_prompt`.

Notes on scoring-relevant fields (the client-side scoring engine lives in the Phase 1
Flutter app, pure Dart, no network):
- `fill_in_open` and `grammar_transformation` carry `accepted_answers` (an array, since
  grammar transforms often have 2-3 valid forms) plus `fuzzy_tolerance` (max Levenshtein
  distance still counted correct) and `case_sensitive`. Both default at build time so
  the values are baked into the pack -- the Dart engine never needs a second config
  source to stay in sync with content authored later.
- `mcq`, `fill_in_word_bank`, `matching`, `rearranging` are exact-match only (closed
  answer sets), never fuzzy.
- `writing_prompt` has no auto-score: it carries a `model_answer_en` and a
  `rubric_checklist` for the student's self-check flow.
- `comprehension_set` nests a `passage_en` plus `sub_questions`, each a reduced
  `mcq` / `fill_in_word_bank` / `fill_in_open` / `matching` object that inherits the
  parent's `topic`/`paper` unless it overrides `topic`/`subtopic` itself.
- True/False is modeled as a 2-option `mcq` (`A` = True, `B` = False) rather than a
  10th type. Flagged for a teacher's sanity check during Phase 0 validation.

## Versioning

- `schema_version` (in the manifest) is a semver string for this schema file. Bump the
  minor version for additive, backward-compatible changes (new optional field, new enum
  value); bump the major version for anything that would break an already-shipped app
  build (removed/renamed field, narrowed enum, new required field).
- `pack_version` is a simple incrementing integer per generated `content_pack_v{N}.json`.
  It's independent of `schema_version` -- a new pack can ship under the same schema
  version if only content (not shape) changed.
- The DRAFT topic map (`content/topic-map/topic-map.yaml`) is expected to change before
  its weights are teacher-confirmed; that does not require a schema version bump since
  `topic`/`subtopic` are free-text strings validated only by cross-reference, not by enum.
