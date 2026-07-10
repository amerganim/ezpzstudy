"use strict";

// One-off generator for content/samples/sample-questions.xlsx -- the Phase 0
// exit-criteria proof run, authored by the developer standing in for
// not-yet-recruited teachers. Run manually:
//   node scripts/generate-sample-questions.js
// Spans all 9 question types (24 top-level items + 2 nested comprehension
// sub-questions = 26 authored items total), exceeding the master plan's
// "20 questions" minimum bar.

const path = require("path");
const ExcelJS = require("exceljs");
const { TABS, COMPREHENSION_PASSAGE_COLUMNS, tabColumns } = require("../src/columns");

const AUTHOR = "dev-sample";
const REVIEW = "published";

function row(overrides) {
  return {
    review_status: REVIEW,
    author: AUTHOR,
    tags: "",
    subtopic: "",
    ...overrides,
  };
}

const rowsByTab = {
  flashcard: [
    row({
      id: "vocab-01", paper: "2nd", topic: "vocabulary_hsc_words", difficulty: "medium", marks_weight: 1,
      instruction_bn: "শব্দটির অর্থ ও ব্যবহার শেখো", explanation_bn: "Abundant একটি বিশেষণ (adjective), অর্থ 'প্রচুর'।",
      front_en: "Abundant", back_bn: "প্রচুর",
      example_sentence_en: "Bangladesh has abundant water resources.",
      part_of_speech: "adjective", synonym: "plentiful", antonym: "scarce",
    }),
    row({
      id: "vocab-02", paper: "2nd", topic: "vocabulary_hsc_words", difficulty: "medium", marks_weight: 1,
      instruction_bn: "শব্দটির অর্থ ও ব্যবহার শেখো", explanation_bn: "Diligent একটি বিশেষণ, অর্থ 'পরিশ্রমী'।",
      front_en: "Diligent", back_bn: "পরিশ্রমী",
      example_sentence_en: "A diligent student never wastes time.",
      part_of_speech: "adjective", synonym: "hardworking", antonym: "lazy",
    }),
    row({
      id: "vocab-03", paper: "2nd", topic: "vocabulary_hsc_words", difficulty: "medium", marks_weight: 1,
      instruction_bn: "শব্দটির অর্থ ও ব্যবহার শেখো", explanation_bn: "Reluctant একটি বিশেষণ, অর্থ 'অনিচ্ছুক'।",
      front_en: "Reluctant", back_bn: "অনিচ্ছুক",
      example_sentence_en: "He was reluctant to answer the question.",
      part_of_speech: "adjective", synonym: "unwilling", antonym: "eager",
    }),
    row({
      id: "vocab-04", paper: "2nd", topic: "vocabulary_hsc_words", difficulty: "easy", marks_weight: 1,
      instruction_bn: "শব্দটির অর্থ ও ব্যবহার শেখো", explanation_bn: "Generous একটি বিশেষণ, অর্থ 'উদার'।",
      front_en: "Generous", back_bn: "উদার",
      example_sentence_en: "She is generous to the poor.",
      part_of_speech: "adjective", synonym: "kind", antonym: "selfish",
    }),
    row({
      id: "vocab-05", paper: "2nd", topic: "vocabulary_hsc_words", difficulty: "hard", marks_weight: 1,
      instruction_bn: "শব্দটির অর্থ ও ব্যবহার শেখো", explanation_bn: "Benevolent একটি বিশেষণ, অর্থ 'দয়ালু'।",
      front_en: "Benevolent", back_bn: "দয়ালু",
      example_sentence_en: "The benevolent king helped his people.",
      part_of_speech: "adjective", synonym: "kind", antonym: "cruel",
    }),
  ],

  mcq: [
    row({
      id: "tense-01", paper: "2nd", topic: "tense", difficulty: "medium", marks_weight: 1, tags: "exam-common",
      instruction_bn: "সঠিক কাল (tense) বেছে নাও", explanation_bn: "একটি past action-এর আগে ঘটা আরেকটি past action বোঝাতে Past Perfect (had + V3) ব্যবহার হয়।",
      question_en: 'By the time she reached the station, the train ___ (leave).',
      option_a: "leaves", option_b: "left", option_c: "had left", option_d: "has left", correct_option: "C",
    }),
    row({
      id: "tense-02", paper: "2nd", topic: "tense", difficulty: "hard", marks_weight: 1, tags: "exam-common",
      instruction_bn: "সঠিক কাল (tense) বেছে নাও", explanation_bn: "অতীতে শুরু হয়ে এখনও চলছে এমন কাজ বোঝাতে Present Perfect Continuous (have/has been + V-ing) ব্যবহার হয়।",
      question_en: "I ___ English for five years.",
      option_a: "learn", option_b: "learnt", option_c: "have learnt", option_d: "have been learning", correct_option: "D",
    }),
    row({
      id: "prep-01", paper: "2nd", topic: "preposition", difficulty: "easy", marks_weight: 1, tags: "exam-common",
      instruction_bn: "সঠিক preposition বেছে নাও", explanation_bn: "'Fond of' একটি নির্দিষ্ট (fixed) preposition phrase।",
      question_en: "She is fond ___ music.",
      option_a: "of", option_b: "with", option_c: "in", option_d: "at", correct_option: "A",
    }),
    row({
      id: "prep-02", paper: "2nd", topic: "preposition", difficulty: "easy", marks_weight: 1,
      instruction_bn: "সঠিক preposition বেছে নাও", explanation_bn: "'On time' মানে নির্ধারিত সময়ে, যা একটি fixed phrase।",
      question_en: "The train arrived ___ time.",
      option_a: "in", option_b: "on", option_c: "at", option_d: "by", correct_option: "B",
    }),
    row({
      id: "vocab-mcq-01", paper: "2nd", topic: "vocabulary_hsc_words", difficulty: "medium", marks_weight: 1,
      instruction_bn: "'Abundant' শব্দটির সমার্থক শব্দ (synonym) বেছে নাও", explanation_bn: "Abundant = Plentiful (প্রচুর); Scarce ও Rare এর অর্থ উল্টো।",
      question_en: "Choose the synonym of 'Abundant'.",
      option_a: "Scarce", option_b: "Plentiful", option_c: "Rare", option_d: "Limited", correct_option: "B",
    }),
    row({
      id: "vocab-mcq-02", paper: "2nd", topic: "vocabulary_hsc_words", difficulty: "medium", marks_weight: 1,
      instruction_bn: "'Diligent' শব্দটির বিপরীত শব্দ (antonym) বেছে নাও", explanation_bn: "Diligent = পরিশ্রমী; এর বিপরীত হলো Lazy (অলস)।",
      question_en: "Choose the antonym of 'Diligent'.",
      option_a: "Hardworking", option_b: "Active", option_c: "Lazy", option_d: "Sincere", correct_option: "C",
    }),
  ],

  fill_in_word_bank: [
    row({
      id: "tense-fiwb-01", paper: "2nd", topic: "tense", difficulty: "easy", marks_weight: 1,
      instruction_bn: "শব্দভাণ্ডার থেকে সঠিক শব্দ বেছে খালি ঘর পূরণ করো", explanation_bn: "নিয়মিত/অভ্যাসগত কাজ বোঝাতে Present Indefinite Tense (verb + s/es) ব্যবহার হয়।",
      sentence_en: "She {{1}} to school every day.",
      word_bank: "goes,go,going,gone", answer_1: "goes",
    }),
    row({
      id: "tense-fiwb-02", paper: "2nd", topic: "tense", difficulty: "medium", marks_weight: 1,
      instruction_bn: "শব্দভাণ্ডার থেকে সঠিক শব্দ বেছে খালি ঘর পূরণ করো", explanation_bn: "অতীতে চলমান একটি কাজ বোঝাতে Past Continuous Tense (was/were + V-ing) ব্যবহার হয়।",
      sentence_en: "They {{1}} football when it started to rain.",
      word_bank: "played,were playing,play,plays", answer_1: "were playing",
    }),
    row({
      id: "prep-fiwb-01", paper: "2nd", topic: "preposition", difficulty: "easy", marks_weight: 1,
      instruction_bn: "শব্দভাণ্ডার থেকে সঠিক preposition বেছে খালি ঘর পূরণ করো", explanation_bn: "'Good at' একটি fixed preposition phrase, দক্ষতা বোঝাতে ব্যবহৃত হয়।",
      sentence_en: "He is good {{1}} mathematics.",
      word_bank: "at,in,on,of", answer_1: "at",
    }),
    row({
      id: "prep-fiwb-02", paper: "2nd", topic: "preposition", difficulty: "medium", marks_weight: 1,
      instruction_bn: "শব্দভাণ্ডার থেকে সঠিক preposition বেছে খালি ঘর পূরণ করো", explanation_bn: "'Famous for' একটি fixed preposition phrase, কোনো কিছুর জন্য পরিচিতি বোঝাতে ব্যবহৃত হয়।",
      sentence_en: "Dhaka is famous {{1}} its rich culture.",
      word_bank: "for,of,with,about", answer_1: "for",
    }),
  ],

  fill_in_open: [
    row({
      id: "rfv-01", paper: "2nd", topic: "right_form_of_verb", difficulty: "hard", marks_weight: 1,
      instruction_bn: "বন্ধনীর ক্রিয়াপদের সঠিক রূপ লেখো", explanation_bn: "শর্তসাপেক্ষ (conditional) বাক্যে 'if' এর পর কাল্পনিক অবস্থা বোঝাতে 'were' ব্যবহার হয়, 'was' নয়।",
      sentence_en: "If I ___ (be) you, I would study harder.",
      accepted_answers: "were", fuzzy_tolerance: 0, case_sensitive: "N",
    }),
    row({
      id: "rfv-02", paper: "2nd", topic: "right_form_of_verb", difficulty: "medium", marks_weight: 1,
      instruction_bn: "বন্ধনীর ক্রিয়াপদের সঠিক রূপ লেখো", explanation_bn: "Present Perfect Tense-এ verb-এর V3 (past participle) রূপ ব্যবহার হয়।",
      sentence_en: "She has ___ (finish) her assignment already.",
      accepted_answers: "finished", fuzzy_tolerance: 1, case_sensitive: "N",
    }),
    row({
      id: "rfv-03", paper: "2nd", topic: "right_form_of_verb", difficulty: "hard", marks_weight: 1,
      instruction_bn: "বন্ধনীর ক্রিয়াপদের সঠিক রূপ লেখো", explanation_bn: "Passive Voice-এ Past Simple বোঝাতে 'was/were + V3' ব্যবহার হয়।",
      sentence_en: "The Padma Bridge ___ (build) in 2022.",
      accepted_answers: "was built", fuzzy_tolerance: 1, case_sensitive: "N",
    }),
  ],

  grammar_transformation: [
    row({
      id: "voice-01", paper: "2nd", topic: "voice", difficulty: "medium", marks_weight: 2,
      instruction_bn: "বাক্যটিকে Passive Voice-এ পরিণত করো", explanation_bn: "Active-কে Passive করতে object-কে subject করে 'be + V3 + by + subject' গঠন ব্যবহার করতে হয়।",
      transformation_type: "voice", original_sentence_en: "The teacher teaches the students.",
      accepted_answers: "The students are taught by the teacher.",
      fuzzy_tolerance: 2, case_sensitive: "N",
    }),
    row({
      id: "narr-01", paper: "2nd", topic: "narration", difficulty: "hard", marks_weight: 2,
      instruction_bn: "বাক্যটিকে Indirect Narration-এ পরিণত করো", explanation_bn: "Direct-কে Indirect করতে reporting verb ও tense পরিবর্তন করতে হয়; 'am' হয়ে যায় 'was'।",
      transformation_type: "narration", original_sentence_en: 'He said, "I am reading a book."',
      accepted_answers: "He said that he was reading a book.",
      fuzzy_tolerance: 3, case_sensitive: "N",
    }),
  ],

  matching: [
    row({
      id: "match-01", paper: "2nd", topic: "tense", difficulty: "easy", marks_weight: 2,
      instruction_bn: "বাম পাশের শব্দের সাথে ডান পাশের সঠিক ব্যাখ্যা মেলাও", explanation_bn: "প্রতিটি ব্যাকরণ পরিভাষার একটি নির্দিষ্ট সংজ্ঞা আছে।",
      left_1: "Tense", right_1: "Grammar of time",
      left_2: "Voice", right_2: "Active or passive form of a verb",
      left_3: "Narration", right_3: "Reporting someone's words",
      left_4: "Preposition", right_4: "Shows relation between words",
    }),
  ],

  rearranging: [
    row({
      id: "rearr-01", paper: "1st", topic: "rearranging_sentences", difficulty: "medium", marks_weight: 2,
      instruction_bn: "বাক্যগুলোকে সঠিক ক্রমে সাজাও", explanation_bn: "একটি অনুচ্ছেদের বাক্যগুলো সময়ের ক্রম (order of events) অনুসারে সাজাতে হয়।",
      unit_type: "sentence",
      unit_1: "Yesterday it rained heavily in Dhaka.",
      unit_2: "The streets were flooded with water.",
      unit_3: "Many people faced difficulty going to work.",
      unit_4: "By evening, the rain finally stopped.",
    }),
  ],

  writing_prompt: [
    row({
      id: "app-letter-01", paper: "2nd", topic: "application_letter", difficulty: "medium", marks_weight: 10,
      instruction_bn: "নমুনা অনুযায়ী আবেদনপত্রটি লেখো, তারপর নিজে যাচাই করো", explanation_bn: "মডেল উত্তর ও রুব্রিক চেকলিস্ট দেখে নিজের লেখা যাচাই করো।",
      writing_type: "application",
      prompt_en: "Write an application to your Headteacher requesting the establishment of a school library.",
      word_limit_min: 100, word_limit_max: 150,
      model_answer_en:
        "To\nThe Headteacher\n[School Name]\n[Address]\n\nDate: [Date]\n\nSubject: Application for establishing a school library\n\nDear Sir,\n\nI am writing on behalf of the students of this school to request the establishment of a library. We currently have no dedicated space to read books beyond our textbooks, which limits our access to general knowledge and literature. A library would greatly help us develop good reading habits and improve our results.\n\nI therefore hope you will kindly consider setting up a library for us.\n\nYours obediently,\n[Your Name]\nClass [X], Roll [Y]",
      rubric_1_bn: "সঠিক ফরম্যাট (প্রেরক/প্রাপক/তারিখ) ব্যবহার করা হয়েছে",
      rubric_2_bn: "Subject লাইন স্পষ্টভাবে লেখা হয়েছে",
      rubric_3_bn: "আবেদনের কারণ যুক্তিসঙ্গতভাবে ব্যাখ্যা করা হয়েছে",
      rubric_4_bn: "ভদ্র ও আনুষ্ঠানিক ভাষা ব্যবহার করা হয়েছে",
    }),
  ],
};

const passageRows = [
  row({
    passage_id: "passage-village-fair", paper: "1st", topic: "seen_comprehension", difficulty: "medium", marks_weight: 6,
    instruction_bn: "অনুচ্ছেদটি পড়ে নিচের প্রশ্নগুলোর উত্তর দাও", explanation_bn: "প্রতিটি উপ-প্রশ্নের নিজস্ব ব্যাখ্যা নিচে দেওয়া আছে।",
    passage_en:
      "Once a year, a big fair is held in Bishpur village. Villagers from nearby areas gather there to buy and sell various things. Toys, sweets, and handicrafts are sold at the fair. Folk singers perform songs, and children enjoy merry-go-rounds. The fair usually starts in the morning and continues till late evening. It brings joy and a sense of togetherness to the whole village.",
    passage_source: "original",
  }),
];

const passageSubQuestions = {
  mcq: [
    row({
      id: "q1", paper: "2nd", passage_id: "passage-village-fair", sub_order: 1,
      instruction_bn: "সঠিক উত্তর বেছে নাও", explanation_bn: "অনুচ্ছেদের প্রথম বাক্যে গ্রামের নাম উল্লেখ আছে।",
      question_en: "Where is the fair held?",
      option_a: "Bishpur village", option_b: "Dhaka city", option_c: "Chittagong", option_d: "Sylhet",
      correct_option: "A",
    }),
  ],
  fill_in_open: [
    row({
      id: "q2", paper: "2nd", passage_id: "passage-village-fair", sub_order: 2,
      instruction_bn: "এক কথায় উত্তর লেখো", explanation_bn: "অনুচ্ছেদে বলা হয়েছে, folk singers গান পরিবেশন করেন।",
      sentence_en: "What do folk singers do at the fair?",
      accepted_answers: "perform songs|sing songs|sing",
      fuzzy_tolerance: 2, case_sensitive: "N",
    }),
  ],
};

async function main() {
  const workbook = new ExcelJS.Workbook();

  for (const tabName of TABS) {
    const sheet = workbook.addWorksheet(tabName);
    const columns = tabColumns(tabName);
    sheet.addRow(columns);
    const standaloneRows = rowsByTab[tabName] || [];
    const linkedRows = passageSubQuestions[tabName] || [];
    for (const rowData of [...standaloneRows, ...linkedRows]) {
      sheet.addRow(columns.map((c) => (rowData[c] !== undefined ? rowData[c] : "")));
    }
  }

  const passagesSheet = workbook.addWorksheet("comprehension_passages");
  passagesSheet.addRow(COMPREHENSION_PASSAGE_COLUMNS);
  for (const rowData of passageRows) {
    passagesSheet.addRow(COMPREHENSION_PASSAGE_COLUMNS.map((c) => (rowData[c] !== undefined ? rowData[c] : "")));
  }

  const outPath = path.join(__dirname, "..", "..", "..", "content", "samples", "sample-questions.xlsx");
  await workbook.xlsx.writeFile(outPath);
  console.log(`Sample questions written to ${outPath}`);
}

main();
