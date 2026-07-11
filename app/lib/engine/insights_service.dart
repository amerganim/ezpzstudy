import '../data/progress_repository.dart';
import '../data/topic_map_repository.dart';
import 'routing/focus_areas.dart';
import 'scoring/predicted_score.dart';

/// Everything the home screen needs to show engagement + diagnostics state.
class Insights {
  final bool diagnosticDone;
  final PredictedScore predictedScore;
  final List<FocusArea> focusAreas;

  /// True once every assessed topic is above the weak threshold — unlocks the
  /// strong-student Challenge track.
  final bool allClear;

  const Insights({
    required this.diagnosticDone,
    required this.predictedScore,
    required this.focusAreas,
    required this.allClear,
  });
}

/// Assembles the Predicted Board Score and Focus Areas from the topic map and
/// stored progress. Sits above the data layer so the repositories stay free of
/// engine concepts.
class InsightsService {
  final ProgressRepository progress;
  final TopicMapRepository topicMap;
  final PredictedScoreEngine scoreEngine;
  final FocusAreaRouter router;

  const InsightsService({
    required this.progress,
    required this.topicMap,
    this.scoreEngine = const PredictedScoreEngine(),
    this.router = const FocusAreaRouter(),
  });

  Future<Insights> load() async {
    final map = await topicMap.load();
    final snapshot = await progress.snapshot();
    final stats = <String, TopicStat>{
      for (final t in snapshot.topics)
        t.topic: TopicStat(attempts: t.attempts, correct: t.correct),
    };

    return Insights(
      diagnosticDone: await progress.isDiagnosticDone(),
      predictedScore: scoreEngine.compute(map, stats),
      focusAreas: router.buildQueue(map, stats),
      allClear: router.allClear(map, stats),
    );
  }
}
