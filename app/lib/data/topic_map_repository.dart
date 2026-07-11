import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models/topic_map.dart';

/// Loads the compiled topic map from the bundled asset once and caches it.
class TopicMapRepository {
  static const _asset = 'assets/content/topic_map.json';

  TopicMap? _cached;

  Future<TopicMap> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString(_asset);
    _cached = TopicMap.fromJson(json.decode(raw) as Map<String, dynamic>);
    return _cached!;
  }

  /// Test seam: inject a topic map directly.
  // ignore: use_setters_to_change_properties
  void setForTesting(TopicMap map) => _cached = map;
}
