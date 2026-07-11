/// A single topic's board-marks metadata, from the compiled topic map.
class TopicInfo {
  final String id;
  final String labelEn;
  final String paper; // "1st" | "2nd" | "both"
  final num weight; // board-marks weight; 0 for non-scoring (e.g. vocabulary)
  final List<String> remedial; // SSC prerequisite topic ids

  const TopicInfo({
    required this.id,
    required this.labelEn,
    required this.paper,
    required this.weight,
    required this.remedial,
  });

  factory TopicInfo.fromJson(Map<String, dynamic> json) => TopicInfo(
        id: json['id'] as String,
        labelEn: json['label_en'] as String,
        paper: json['paper'] as String,
        weight: json['weight'] as num,
        remedial: (json['remedial'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
      );
}

/// The compiled topic map: weights and remedial links the app reads for the
/// Predicted Board Score and Focus Areas routing. Generated from the
/// authoritative topic-map.yaml, so the app never drifts from validated numbers.
class TopicMap {
  final String schemaVersion;
  final List<TopicInfo> topics;
  final Map<String, String> remedialLabels;

  const TopicMap({
    required this.schemaVersion,
    required this.topics,
    required this.remedialLabels,
  });

  factory TopicMap.fromJson(Map<String, dynamic> json) => TopicMap(
        schemaVersion: json['schema_version'] as String? ?? 'unknown',
        topics: (json['topics'] as List<dynamic>)
            .map((e) => TopicInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        remedialLabels:
            (json['remedial_labels'] as Map<String, dynamic>? ?? const {})
                .map((k, v) => MapEntry(k, v as String)),
      );

  TopicInfo? byId(String id) {
    for (final t in topics) {
      if (t.id == id) return t;
    }
    return null;
  }

  num weightOf(String topicId) => byId(topicId)?.weight ?? 0;

  /// Total board weight across all scoring topics (weight > 0).
  num get totalWeight =>
      topics.fold<num>(0, (sum, t) => sum + (t.weight > 0 ? t.weight : 0));
}
