import '../../data/models/topic_map.dart';

/// A topic's assessed performance (from the diagnostic and/or ongoing practice).
class TopicStat {
  final int attempts;
  final int correct;
  const TopicStat({required this.attempts, required this.correct});

  double get accuracy => attempts == 0 ? 0 : correct / attempts;
}

/// The weighted Predicted Board Score — the app's killer feature. It answers
/// "will I pass?" by projecting the student's accuracy across topics, weighted
/// by each topic's real board-marks weight.
class PredictedScore {
  /// Weighted marks the student is projected to earn on assessed topics:
  /// sum of (accuracy x weight) over topics that have any data.
  final double earnedMarks;

  /// Total weight of topics that have been assessed (the projection's basis).
  final double assessedWeight;

  /// Total weight of all scoring topics — the whole syllabus.
  final double totalWeight;

  const PredictedScore({
    required this.earnedMarks,
    required this.assessedWeight,
    required this.totalWeight,
  });

  /// Whether enough has been assessed to show a score at all.
  bool get available => assessedWeight > 0;

  /// Projected board percentage, honest: computed only over what's been
  /// assessed, not assuming anything about untouched topics.
  int get percent =>
      available ? (earnedMarks / assessedWeight * 100).round() : 0;

  /// Fraction of the syllabus (by weight) that has been assessed so far. Lets
  /// the UI say "based on X% of the syllabus so far" and nudge broader practice.
  double get coverage => totalWeight == 0 ? 0 : assessedWeight / totalWeight;
}

class PredictedScoreEngine {
  const PredictedScoreEngine();

  /// [progress] maps topic id -> assessed stat. Untested topics contribute to
  /// [PredictedScore.totalWeight] (coverage) but not to the projection itself.
  PredictedScore compute(TopicMap map, Map<String, TopicStat> progress) {
    double earned = 0;
    double assessedWeight = 0;
    double totalWeight = 0;

    for (final topic in map.topics) {
      final w = topic.weight.toDouble();
      if (w <= 0) continue; // vocabulary etc. — not a board-marks input
      totalWeight += w;

      final stat = progress[topic.id];
      if (stat == null || stat.attempts == 0) continue;
      assessedWeight += w;
      earned += stat.accuracy * w;
    }

    return PredictedScore(
      earnedMarks: earned,
      assessedWeight: assessedWeight,
      totalWeight: totalWeight,
    );
  }
}
