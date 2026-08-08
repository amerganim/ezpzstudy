import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// The whole question bank. Envelope fields are typed columns; the type-specific
/// payload is a single JSON text column (`dataJson`), exactly mirroring the
/// content-pack schema's envelope + `data` design. This keeps topic/type queries
/// on indexed columns while letting the nested, per-type shapes stay flexible.
@DataClassName('QuestionRow')
class Questions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get paper => text()();
  TextColumn get topic => text()();
  TextColumn get subtopic => text().nullable()();
  TextColumn get difficulty => text()();
  RealColumn get marksWeight => real()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get instructionBn => text()();
  TextColumn get explanationBn => text()();
  TextColumn get reviewStatus => text()();
  TextColumn get author => text()();
  TextColumn get dataJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Aggregated progress per topic — attempts, correct, last practiced. Never one
/// row per attempt (per the master plan's critical schema rule). This is also
/// exactly the shape the future /sync endpoint will send.
class TopicProgress extends Table {
  TextColumn get topic => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get correct => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPracticed => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {topic};
}

/// Per-flashcard spaced-repetition state (SM-2).
@DataClassName('FlashcardSrsData')
class FlashcardSrs extends Table {
  TextColumn get questionId => text()();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueDate => dateTime()();

  @override
  Set<Column> get primaryKey => {questionId};
}

/// Small key-value store for global app state: content pack version, streak
/// days, last practice date, total sessions.
class Meta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Questions, TopicProgress, FlashcardSrs, Meta])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() => driftDatabase(
        name: 'ezpzstudy',
        // Required on web: drift loads sqlite3 + its worker from these urls,
        // which are the files shipped in web/ (sqlite3.wasm, drift_worker.js).
        // Ignored on native (Android), which keeps its default file storage.
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
        native: const DriftNativeOptions(),
      );

  // ---- Meta helpers --------------------------------------------------------

  Future<String?> getMeta(String key) async {
    final row = await (select(meta)..where((m) => m.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String key, String value) => into(meta).insertOnConflictUpdate(
        MetaCompanion.insert(key: key, value: value),
      );

  // ---- Questions -----------------------------------------------------------

  Future<int> questionCount() async {
    final count = countAll();
    final row =
        await (selectOnly(questions)..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<QuestionRow>> questionsForTopic(String topic) =>
      (select(questions)..where((q) => q.topic.equals(topic))).get();

  Future<List<String>> distinctTopics() async {
    final rows = await (selectOnly(questions, distinct: true)
          ..addColumns([questions.topic]))
        .get();
    return rows.map((r) => r.read(questions.topic)!).toList();
  }

  Future<List<QuestionRow>> questionsOfType(String type) =>
      (select(questions)..where((q) => q.type.equals(type))).get();

  // ---- Topic progress ------------------------------------------------------

  Future<TopicProgressData> recordAttempt({
    required String topic,
    required bool correct,
    required DateTime when,
  }) async {
    return transaction(() async {
      final existing = await (select(topicProgress)
            ..where((t) => t.topic.equals(topic)))
          .getSingleOrNull();
      final attempts = (existing?.attempts ?? 0) + 1;
      final correctCount = (existing?.correct ?? 0) + (correct ? 1 : 0);
      final companion = TopicProgressCompanion.insert(
        topic: topic,
        attempts: Value(attempts),
        correct: Value(correctCount),
        lastPracticed: Value(when),
      );
      await into(topicProgress).insertOnConflictUpdate(companion);
      return TopicProgressData(
        topic: topic,
        attempts: attempts,
        correct: correctCount,
        lastPracticed: when,
      );
    });
  }

  Future<List<TopicProgressData>> allProgress() => select(topicProgress).get();

  // ---- Flashcard SRS -------------------------------------------------------

  Future<FlashcardSrsData?> srsFor(String questionId) =>
      (select(flashcardSrs)..where((s) => s.questionId.equals(questionId)))
          .getSingleOrNull();

  Future<void> upsertSrs(FlashcardSrsCompanion companion) =>
      into(flashcardSrs).insertOnConflictUpdate(companion);

  /// Flashcard question ids whose review is due on or before [asOf].
  Future<List<String>> dueFlashcardIds(DateTime asOf) async {
    final rows = await (select(flashcardSrs)
          ..where((s) => s.dueDate.isSmallerOrEqualValue(asOf)))
        .get();
    return rows.map((r) => r.questionId).toList();
  }
}
