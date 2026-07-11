import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'db/database.dart';

/// Loads the content pack that ships inside the APK into the local SQLite store
/// on first run (or when a newer pack version is bundled). The app never pays
/// data to download questions — everything is already in assets.
class ContentLoader {
  final AppDatabase db;
  const ContentLoader(this.db);

  static const _packAsset = 'assets/content/content_pack_v8.json';
  static const _manifestAsset = 'assets/content/manifest_v8.json';
  static const _loadedVersionKey = 'content_pack_version';

  /// Ensures the DB question bank matches the bundled pack. Idempotent: if the
  /// bundled pack version is already loaded, does nothing.
  Future<void> ensureLoaded() async {
    final manifestRaw = await rootBundle.loadString(_manifestAsset);
    final manifest = json.decode(manifestRaw) as Map<String, dynamic>;
    final bundledVersion = (manifest['pack_version'] as num).toInt();

    final loadedVersion = await db.getMeta(_loadedVersionKey);
    if (loadedVersion == bundledVersion.toString() &&
        await db.questionCount() > 0) {
      return; // already up to date
    }

    final packRaw = await rootBundle.loadString(_packAsset);
    final pack = json.decode(packRaw) as List<dynamic>;

    await db.batch((batch) {
      batch.deleteAll(db.questions);
      for (final entry in pack) {
        final q = entry as Map<String, dynamic>;
        batch.insert(
          db.questions,
          QuestionsCompanion.insert(
            id: q['id'] as String,
            type: q['type'] as String,
            paper: q['paper'] as String,
            topic: q['topic'] as String,
            subtopic: Value(q['subtopic'] as String?),
            difficulty: q['difficulty'] as String,
            marksWeight: (q['marks_weight'] as num).toDouble(),
            tagsJson: Value(json.encode(q['tags'] ?? const [])),
            instructionBn: q['instruction_bn'] as String,
            explanationBn: q['explanation_bn'] as String,
            reviewStatus: q['review_status'] as String,
            author: q['author'] as String,
            dataJson: json.encode(q['data']),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });

    await db.setMeta(_loadedVersionKey, bundledVersion.toString());
  }
}
