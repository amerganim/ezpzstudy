/// Display labels for topic ids. Topics are surfaced as neutral skill areas
/// (e.g. "Tense") — never labeled by class level, per the product philosophy.
///
/// English grammar terms are ones students already recognize; a short Bangla
/// gloss is added where it helps. Falls back to a prettified id for anything
/// not listed, so a newly added topic still renders sensibly.
class TopicLabels {
  const TopicLabels._();

  // Bangla-first labels, mirroring topic-map.yaml's label_bn. Kept in sync with
  // the compiled topic map; the prettified fallback covers anything unlisted.
  static const Map<String, String> _labels = {
    // Basics track (Pass-first foundations)
    'basics_sentence_structure': 'বাক্য গঠন',
    'basics_parts_of_speech': 'Parts of Speech (পদ পরিচিতি)',
    'tense': 'Tense (কাল)',
    'basics_verb_forms': 'Verb-এর রূপ (V1–V5)',
    'basics_subject_verb': 'Subject–Verb মিল',
    'basics_articles': 'Article (a/an/the)',
    'basics_prepositions': 'Preposition (সাধারণ)',
    'basics_wh_questions': 'Wh-প্রশ্ন গঠন',
    'basics_punctuation': 'বড় হাতের অক্ষর ও যতিচিহ্ন',
    'basics_everyday_vocab': 'দৈনন্দিন শব্দ',
    // HSC 1st Paper
    'p1_mcq': 'Reading — MCQ',
    'p1_short_answer': 'সংক্ষিপ্ত প্রশ্নের উত্তর',
    'p1_info_transfer': 'তথ্য স্থানান্তর / Flow Chart',
    'p1_summary': 'Summary লেখা',
    'p1_cloze_clues': 'Cloze Test (clue সহ)',
    'p1_cloze_no_clues': 'Cloze Test (clue ছাড়া)',
    'p1_rearranging': 'বাক্য সাজানো (Rearranging)',
    'p1_graph_chart': 'Graph / Chart বর্ণনা',
    'p1_story_writing': 'Story লেখা',
    'p1_informal_letter': 'Informal Letter',
    // HSC 2nd Paper
    'p2_preposition': 'Preposition (শূন্যস্থান)',
    'p2_special_use': 'Special Use (clue সহ শূন্যস্থান)',
    'p2_completing_sentences': 'Completing Sentences (clause/phrase)',
    'p2_right_form_verb': 'Right Form of Verbs ও Subject–Verb মিল',
    'p2_narration': 'Narration (Direct/Indirect)',
    'p2_modifier': 'Modifier',
    'p2_connectors': 'Sentence Connectors (linking words)',
    'p2_synonym_antonym': 'Synonym ও Antonym',
    'p2_punctuation': 'Punctuation (যতিচিহ্ন)',
    'p2_formal_letter': 'Formal Letter / Email',
    'p2_paragraph_listing': 'Paragraph (listing/বর্ণনা)',
    'p2_paragraph_compare': 'Paragraph (তুলনা/কারণ-ফল)',
    // Cross-cutting
    'vocabulary_hsc_words': 'HSC শব্দভাণ্ডার',
  };

  static String of(String topicId) {
    final known = _labels[topicId];
    if (known != null) return known;
    // Prettify: ssc_tense_basics -> "Tense Basics"
    return topicId
        .replaceFirst(RegExp(r'^ssc_'), '')
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
