import '../../data/models/topic_map.dart';
import '../scoring/predicted_score.dart';

/// One weak topic surfaced to the student. Ranked so the highest-impact,
/// weakest topic comes first. Framed as a skill area ("Focus Area: Tense"),
/// never by class level.
class FocusArea {
  final String topicId;
  final String labelEn;
  final double accuracy; // 0..1
  final int attempts;
  final num weight;

  /// Priority score used for ranking (higher = practice sooner). Combines how
  /// weak the topic is with how many marks it's worth.
  final double priority;

  const FocusArea({
    required this.topicId,
    required this.labelEn,
    required this.accuracy,
    required this.attempts,
    required this.weight,
    required this.priority,
  });

  /// A rough "you'd score N/10 today" framing for this topic.
  int get scoreOutOfTen => (accuracy * 10).round();
}

/// Turns diagnostic + ongoing accuracy into a ranked Focus Areas queue, and
/// decides when a topic is "cleared". Removes the burden of deciding what to
/// study — exactly what weak students can't do for themselves.
class FocusAreaRouter {
  /// A topic counts as a focus area while accuracy is below this.
  final double weakThreshold;

  /// A topic is cleared once accuracy reaches this (with enough attempts).
  final double clearThreshold;

  /// Minimum attempts before a topic's accuracy is trusted enough to clear it.
  final int minAttemptsToClear;

  const FocusAreaRouter({
    this.weakThreshold = 0.6,
    this.clearThreshold = 0.7,
    this.minAttemptsToClear = 6,
  });

  /// Builds the ranked queue. Only topics that have been assessed (attempts > 0)
  /// and are still weak are included — you can't be told a topic is weak before
  /// it's been measured.
  List<FocusArea> buildQueue(TopicMap map, Map<String, TopicStat> progress) {
    final areas = <FocusArea>[];
    for (final topic in map.topics) {
      final stat = progress[topic.id];
      if (stat == null || stat.attempts == 0) continue;
      final accuracy = stat.accuracy;
      if (accuracy >= weakThreshold) continue;

      // Priority: weakness (1 - accuracy) amplified by marks weight. A weak,
      // high-marks topic outranks a weak, low-marks one. Weight-0 topics
      // (vocabulary) still surface, just ranked by weakness alone.
      final w = topic.weight.toDouble();
      final priority = (1 - accuracy) * (1 + w);
      areas.add(FocusArea(
        topicId: topic.id,
        labelEn: topic.labelEn,
        accuracy: accuracy,
        attempts: stat.attempts,
        weight: topic.weight,
        priority: priority,
      ));
    }
    areas.sort((a, b) => b.priority.compareTo(a.priority));
    return areas;
  }

  /// Whether a topic has been mastered enough to drop out of Focus Areas.
  bool isCleared(TopicStat? stat) {
    if (stat == null) return false;
    return stat.attempts >= minAttemptsToClear &&
        stat.accuracy >= clearThreshold;
  }

  /// True once the student has assessed topics and none remain weak — the gate
  /// that unlocks the strong-student Challenge track.
  bool allClear(TopicMap map, Map<String, TopicStat> progress) {
    var assessedAny = false;
    for (final topic in map.topics) {
      final stat = progress[topic.id];
      if (stat == null || stat.attempts == 0) continue;
      assessedAny = true;
      if (stat.accuracy < weakThreshold) return false;
    }
    return assessedAny;
  }
}
