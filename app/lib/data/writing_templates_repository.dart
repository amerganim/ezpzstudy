import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One fillable slot in a writing template. [example] is a ready sample value,
/// shown (greyed) in the live preview whenever the student hasn't typed their
/// own — so a complete model answer is always visible.
class TemplateSlot {
  final String key;
  final String labelBn;
  final String example;

  const TemplateSlot({
    required this.key,
    required this.labelBn,
    required this.example,
  });

  factory TemplateSlot.fromJson(Map<String, dynamic> j) => TemplateSlot(
        key: j['key'] as String,
        labelBn: j['label_bn'] as String? ?? '',
        example: j['example'] as String? ?? '',
      );
}

/// A ready-made writing skeleton (paragraph, letter, dialogue, …). The
/// [skeleton] is exam-safe English with `{key}` placeholders that the student
/// fills — mostly just the topic name — to get a structured, ~50-60% answer.
class WritingTemplate {
  final String id;
  final String category;
  final String categoryBn;
  final String titleBn;
  final int? marks;
  final String introBn;
  final List<TemplateSlot> slots;
  final String skeleton;
  final List<String> tipsBn;

  const WritingTemplate({
    required this.id,
    required this.category,
    required this.categoryBn,
    required this.titleBn,
    required this.marks,
    required this.introBn,
    required this.slots,
    required this.skeleton,
    required this.tipsBn,
  });

  factory WritingTemplate.fromJson(Map<String, dynamic> j) => WritingTemplate(
        id: j['id'] as String,
        category: j['category'] as String? ?? '',
        categoryBn: j['category_bn'] as String? ?? '',
        titleBn: j['title_bn'] as String? ?? '',
        marks: (j['marks'] as num?)?.toInt(),
        introBn: j['intro_bn'] as String? ?? '',
        slots: (j['slots'] as List<dynamic>? ?? const [])
            .map((e) => TemplateSlot.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        skeleton: j['skeleton'] as String? ?? '',
        tipsBn: (j['tips_bn'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
      );

  /// The skeleton with each `{key}` replaced. For every slot, [values] is used
  /// if the student typed something, otherwise the slot's [example], so the
  /// result is always a complete answer.
  String fill(Map<String, String> values) {
    var out = skeleton;
    for (final s in slots) {
      final v = (values[s.key] ?? '').trim();
      out = out.replaceAll('{${s.key}}', v.isEmpty ? s.example : v);
    }
    return out;
  }
}

/// Loads the bundled writing-template asset once and caches it.
class WritingTemplatesRepository {
  static const _asset = 'assets/content/writing_templates.json';

  List<WritingTemplate>? _cached;

  Future<List<WritingTemplate>> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString(_asset);
    final map = json.decode(raw) as Map<String, dynamic>;
    _cached = (map['templates'] as List<dynamic>? ?? const [])
        .map((e) => WritingTemplate.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return _cached!;
  }
}
