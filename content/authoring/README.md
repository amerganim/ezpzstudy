# Content authoring (compact JSON)

Bulk content is authored here as compact JSON — one file per topic — and built
into a content pack with the same schema + semantic validation as the xlsx path.

```
cd tools/content-pipeline
node src/index.js build-json --dir ../../content/authoring \
  --out ../../content/packs/content_pack_v2.json --pack-version 2
```

Each file is one topic:

```json
{
  "topic": "p2_preposition",   // must exist in topic-map.yaml
  "paper": "2nd",              // "1st" | "2nd" | "both"
  "difficulty": "easy",        // default for every item (override per item)
  "author": "ezpz-content",
  "instruction_bn": "…",       // default Bangla instruction for every item
  "items": [ … ]
}
```

Every item needs a `type`, its fields, and `rule_bn` (the one-line Bangla
explanation shown on a wrong answer — never just "Wrong"). Item ids are
generated automatically and are stable as long as item order is unchanged.

## Item shapes by type

| type | fields |
|---|---|
| `flashcard` | `front`, `back_bn`, `example?`, `pos?`, `syn?`, `ant?` |
| `mcq` | `q`, `opts: [..]`, `correct: <index or "A">`, `rule_bn` |
| `fill_in_open` | `q` (use `___` for the blank), `a: [accepted…]`, `fuzzy?`, `case?`, `rule_bn` |
| `fill_in_word_bank` | `q` (use `{{1}}`,`{{2}}`), `bank: [..]`, `ans: [positional]`, `rule_bn` |
| `matching` | `left: [..]`, `right: [..]`, `pairs: [[leftIdx,rightIdx]…]`, `rule_bn` |
| `rearranging` | `answer: "correct order"` (+`unit:"word"`) **or** `sentences: [..]`, `rule_bn` |
| `grammar_transformation` | `original`, `a: [accepted…]`, `transform?`, `fuzzy?`, `rule_bn` |
| `writing_prompt` | `writing_type`, `prompt`, `words?:[min,max]`, `model`, `rubric: [bn…]` |

Notes:
- `fill_in_open`/`grammar_transformation` `a` is a list of accepted answers.
  Fuzzy tolerance defaults to 0 for single-word answers, 2 for phrases; override
  with `fuzzy`.
- `mcq` `correct` may be a 0-based index into `opts` or a letter ("A").
- Content is English; `instruction_bn`/`rule_bn`/flashcard `back_bn` are Bangla.
