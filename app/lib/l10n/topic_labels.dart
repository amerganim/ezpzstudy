/// Display labels for topic ids. Topics are surfaced as neutral skill areas
/// (e.g. "Tense") — never labeled by class level, per the product philosophy.
///
/// English grammar terms are ones students already recognize; a short Bangla
/// gloss is added where it helps. Falls back to a prettified id for anything
/// not listed, so a newly added topic still renders sensibly.
class TopicLabels {
  const TopicLabels._();

  static const Map<String, String> _labels = {
    'tense': 'Tense',
    'right_form_of_verb': 'Right Form of Verbs',
    'subject_verb_agreement': 'Subject–Verb Agreement',
    'voice': 'Voice (Active/Passive)',
    'narration': 'Narration',
    'preposition': 'Preposition',
    'connectors': 'Connectors',
    'tag_questions': 'Tag Questions',
    'sentence_transformation': 'Transformation of Sentences',
    'punctuation': 'Punctuation',
    'articles': 'Articles',
    'vocabulary_hsc_words': 'Vocabulary',
    'seen_comprehension': 'Comprehension',
    'cloze_with_clues': 'Cloze Test (with clues)',
    'cloze_without_clues': 'Cloze Test (no clues)',
    'rearranging_sentences': 'Rearranging',
    'matching': 'Matching',
    'gap_filling_clues': 'Gap Filling',
    'summarizing': 'Summarizing',
    'graph_chart_description': 'Graph/Chart Description',
    'flow_chart_completion': 'Flow Chart Completion',
    'paragraph_writing_1p': 'Paragraph Writing',
    'paragraph_writing_2p': 'Paragraph Writing',
    'essay_writing': 'Essay Writing',
    'application_letter': 'Application/Letter',
    'formal_letter': 'Formal Letter',
    'informal_letter': 'Informal Letter',
    'email_writing': 'Email Writing',
    'cv_writing': 'CV Writing',
    'dialogue_writing': 'Dialogue Writing',
    'report_writing': 'Report Writing',
    'composition_completion': 'Composition Completion',
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
