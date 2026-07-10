# Content authoring template guide / বিষয়বস্তু লেখার নির্দেশিকা

`content-authoring-template.xlsx` is the only thing a teacher needs to touch. No CMS,
no code. Fill it in Excel or Google Sheets, save/export as `.xlsx`, and it becomes a
content pack via one script command.

## English

1. Open the file. The **README** tab has these same instructions.
2. Each question type has its own tab (`flashcard`, `mcq`, `fill_in_word_bank`, ...).
   Write one question per row.
3. Never rename a column header or delete the header row.
4. `topic` has a dropdown -- always pick from it (see the **topics** tab for the full,
   current list). Leave `subtopic` blank unless you have something more specific.
5. `id` only needs to be short and unique *within that tab* (e.g. `tense-01`) -- the
   script adds the paper/type prefix automatically.
6. `explanation_bn` is what the student sees after a wrong answer -- write the actual
   grammar rule in Bangla, in one line, not just "ভুল উত্তর".
7. Leave `review_status` as `draft` until a second teacher has checked your item.
8. For fields that take multiple values (`tags`, `word_bank`), separate with a comma.
   For `accepted_answers` (fill-in-open and grammar transformation), separate with a
   pipe `|` instead, since answers can themselves contain commas.
9. For `matching` and `rearranging`, write the *correct* pairing/order directly into
   the `left_N`/`right_N` or `unit_N` columns in order -- the app scrambles the display
   order on its own; you never need to think about scrambling.
10. To attach a question to a reading passage, add the same `passage_id` (and an
    increasing `sub_order`) on rows in the `mcq` / `fill_in_word_bank` / `fill_in_open` /
    `matching` tabs, and describe the passage itself on the `comprehension_passages` tab.

When you're done, hand the file to the developer (or run, if you have Node installed):

```
node tools/content-pipeline/src/index.js validate --input path/to/your-file.xlsx
```

This checks your file and tells you exactly which row/column has a problem, without
publishing anything.

## বাংলা

১. ফাইলটি খুলুন। **README** ট্যাবে একই নির্দেশনা আছে।
২. প্রতিটি প্রশ্নের ধরনের নিজস্ব ট্যাব আছে। প্রতি সারিতে একটি প্রশ্ন লিখুন।
৩. কলামের শিরোনাম কখনো পরিবর্তন বা মুছে ফেলবেন না।
৪. `topic` কলামে ড্রপডাউন থেকে বেছে নিন (**topics** ট্যাবে সম্পূর্ণ তালিকা আছে)।
৫. `id` শুধু ওই ট্যাবের মধ্যে ছোট ও ইউনিক হলেই চলবে (যেমন `tense-01`)।
৬. `explanation_bn` -- ভুল উত্তরের পর শিক্ষার্থী এটি দেখবে। শুধু "ভুল উত্তর" না লিখে
   প্রকৃত নিয়মটি এক লাইনে লিখুন।
৭. পর্যালোচনার আগ পর্যন্ত `review_status` অবশ্যই `draft` রাখুন।
৮. একাধিক মান দিতে হলে (`tags`, `word_bank`) কমা `,` দিয়ে আলাদা করুন;
   `accepted_answers`-এর ক্ষেত্রে পাইপ `|` ব্যবহার করুন, কারণ উত্তরে কমা থাকতে পারে।
