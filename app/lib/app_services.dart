import 'package:flutter/widgets.dart';

import 'data/content_loader.dart';
import 'data/db/database.dart';
import 'data/flashcard_repository.dart';
import 'data/progress_repository.dart';
import 'data/question_repository.dart';
import 'data/topic_map_repository.dart';
import 'engine/insights_service.dart';
import 'engine/scoring/scoring_engine.dart';

/// Composition root: the single place the app's services are constructed and
/// wired together. Exposed to the widget tree via an [InheritedWidget] so
/// screens can reach them without a third-party DI/state package.
class AppServices {
  final AppDatabase db;
  final QuestionRepository questions;
  final ProgressRepository progress;
  final FlashcardRepository flashcards;
  final TopicMapRepository topicMap;
  final InsightsService insights;
  final ContentLoader contentLoader;
  final ScoringEngine scoring;

  AppServices._({
    required this.db,
    required this.questions,
    required this.progress,
    required this.flashcards,
    required this.topicMap,
    required this.insights,
    required this.contentLoader,
    required this.scoring,
  });

  factory AppServices.create() => AppServices.withDatabase(AppDatabase());

  /// Builds the service graph over a supplied database. Used by [create] with a
  /// real on-device DB, and by tests with an in-memory one.
  factory AppServices.withDatabase(AppDatabase db) {
    final questions = QuestionRepository(db);
    final progress = ProgressRepository(db);
    final topicMap = TopicMapRepository();
    return AppServices._(
      db: db,
      questions: questions,
      progress: progress,
      flashcards: FlashcardRepository(db, questions),
      topicMap: topicMap,
      insights: InsightsService(progress: progress, topicMap: topicMap),
      contentLoader: ContentLoader(db),
      scoring: const ScoringEngine(),
    );
  }

  /// Loads the bundled content pack into the store on first run.
  Future<void> initialize() => contentLoader.ensureLoaded();

  /// Looks up the services without registering an inherited-widget dependency —
  /// the graph is immutable for the app's lifetime, so nothing needs to rebuild
  /// when it's read. This also makes [of] safe to call inside `initState`.
  static AppServices of(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<AppServicesScope>();
    assert(element != null, 'AppServices.of() called outside AppServicesScope');
    return (element!.widget as AppServicesScope).services;
  }
}

class AppServicesScope extends InheritedWidget {
  final AppServices services;

  const AppServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant AppServicesScope oldWidget) =>
      services != oldWidget.services;
}
