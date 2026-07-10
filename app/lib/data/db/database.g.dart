// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $QuestionsTable extends Questions
    with TableInfo<$QuestionsTable, QuestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paperMeta = const VerificationMeta('paper');
  @override
  late final GeneratedColumn<String> paper = GeneratedColumn<String>(
    'paper',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtopicMeta = const VerificationMeta(
    'subtopic',
  );
  @override
  late final GeneratedColumn<String> subtopic = GeneratedColumn<String>(
    'subtopic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _marksWeightMeta = const VerificationMeta(
    'marksWeight',
  );
  @override
  late final GeneratedColumn<double> marksWeight = GeneratedColumn<double>(
    'marks_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _instructionBnMeta = const VerificationMeta(
    'instructionBn',
  );
  @override
  late final GeneratedColumn<String> instructionBn = GeneratedColumn<String>(
    'instruction_bn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationBnMeta = const VerificationMeta(
    'explanationBn',
  );
  @override
  late final GeneratedColumn<String> explanationBn = GeneratedColumn<String>(
    'explanation_bn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewStatusMeta = const VerificationMeta(
    'reviewStatus',
  );
  @override
  late final GeneratedColumn<String> reviewStatus = GeneratedColumn<String>(
    'review_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    paper,
    topic,
    subtopic,
    difficulty,
    marksWeight,
    tagsJson,
    instructionBn,
    explanationBn,
    reviewStatus,
    author,
    dataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('paper')) {
      context.handle(
        _paperMeta,
        paper.isAcceptableOrUnknown(data['paper']!, _paperMeta),
      );
    } else if (isInserting) {
      context.missing(_paperMeta);
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('subtopic')) {
      context.handle(
        _subtopicMeta,
        subtopic.isAcceptableOrUnknown(data['subtopic']!, _subtopicMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('marks_weight')) {
      context.handle(
        _marksWeightMeta,
        marksWeight.isAcceptableOrUnknown(
          data['marks_weight']!,
          _marksWeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_marksWeightMeta);
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('instruction_bn')) {
      context.handle(
        _instructionBnMeta,
        instructionBn.isAcceptableOrUnknown(
          data['instruction_bn']!,
          _instructionBnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instructionBnMeta);
    }
    if (data.containsKey('explanation_bn')) {
      context.handle(
        _explanationBnMeta,
        explanationBn.isAcceptableOrUnknown(
          data['explanation_bn']!,
          _explanationBnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_explanationBnMeta);
    }
    if (data.containsKey('review_status')) {
      context.handle(
        _reviewStatusMeta,
        reviewStatus.isAcceptableOrUnknown(
          data['review_status']!,
          _reviewStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewStatusMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      paper: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paper'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      subtopic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtopic'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      marksWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}marks_weight'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      instructionBn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instruction_bn'],
      )!,
      explanationBn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation_bn'],
      )!,
      reviewStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_status'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
    );
  }

  @override
  $QuestionsTable createAlias(String alias) {
    return $QuestionsTable(attachedDatabase, alias);
  }
}

class QuestionRow extends DataClass implements Insertable<QuestionRow> {
  final String id;
  final String type;
  final String paper;
  final String topic;
  final String? subtopic;
  final String difficulty;
  final double marksWeight;
  final String tagsJson;
  final String instructionBn;
  final String explanationBn;
  final String reviewStatus;
  final String author;
  final String dataJson;
  const QuestionRow({
    required this.id,
    required this.type,
    required this.paper,
    required this.topic,
    this.subtopic,
    required this.difficulty,
    required this.marksWeight,
    required this.tagsJson,
    required this.instructionBn,
    required this.explanationBn,
    required this.reviewStatus,
    required this.author,
    required this.dataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['paper'] = Variable<String>(paper);
    map['topic'] = Variable<String>(topic);
    if (!nullToAbsent || subtopic != null) {
      map['subtopic'] = Variable<String>(subtopic);
    }
    map['difficulty'] = Variable<String>(difficulty);
    map['marks_weight'] = Variable<double>(marksWeight);
    map['tags_json'] = Variable<String>(tagsJson);
    map['instruction_bn'] = Variable<String>(instructionBn);
    map['explanation_bn'] = Variable<String>(explanationBn);
    map['review_status'] = Variable<String>(reviewStatus);
    map['author'] = Variable<String>(author);
    map['data_json'] = Variable<String>(dataJson);
    return map;
  }

  QuestionsCompanion toCompanion(bool nullToAbsent) {
    return QuestionsCompanion(
      id: Value(id),
      type: Value(type),
      paper: Value(paper),
      topic: Value(topic),
      subtopic: subtopic == null && nullToAbsent
          ? const Value.absent()
          : Value(subtopic),
      difficulty: Value(difficulty),
      marksWeight: Value(marksWeight),
      tagsJson: Value(tagsJson),
      instructionBn: Value(instructionBn),
      explanationBn: Value(explanationBn),
      reviewStatus: Value(reviewStatus),
      author: Value(author),
      dataJson: Value(dataJson),
    );
  }

  factory QuestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      paper: serializer.fromJson<String>(json['paper']),
      topic: serializer.fromJson<String>(json['topic']),
      subtopic: serializer.fromJson<String?>(json['subtopic']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      marksWeight: serializer.fromJson<double>(json['marksWeight']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      instructionBn: serializer.fromJson<String>(json['instructionBn']),
      explanationBn: serializer.fromJson<String>(json['explanationBn']),
      reviewStatus: serializer.fromJson<String>(json['reviewStatus']),
      author: serializer.fromJson<String>(json['author']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'paper': serializer.toJson<String>(paper),
      'topic': serializer.toJson<String>(topic),
      'subtopic': serializer.toJson<String?>(subtopic),
      'difficulty': serializer.toJson<String>(difficulty),
      'marksWeight': serializer.toJson<double>(marksWeight),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'instructionBn': serializer.toJson<String>(instructionBn),
      'explanationBn': serializer.toJson<String>(explanationBn),
      'reviewStatus': serializer.toJson<String>(reviewStatus),
      'author': serializer.toJson<String>(author),
      'dataJson': serializer.toJson<String>(dataJson),
    };
  }

  QuestionRow copyWith({
    String? id,
    String? type,
    String? paper,
    String? topic,
    Value<String?> subtopic = const Value.absent(),
    String? difficulty,
    double? marksWeight,
    String? tagsJson,
    String? instructionBn,
    String? explanationBn,
    String? reviewStatus,
    String? author,
    String? dataJson,
  }) => QuestionRow(
    id: id ?? this.id,
    type: type ?? this.type,
    paper: paper ?? this.paper,
    topic: topic ?? this.topic,
    subtopic: subtopic.present ? subtopic.value : this.subtopic,
    difficulty: difficulty ?? this.difficulty,
    marksWeight: marksWeight ?? this.marksWeight,
    tagsJson: tagsJson ?? this.tagsJson,
    instructionBn: instructionBn ?? this.instructionBn,
    explanationBn: explanationBn ?? this.explanationBn,
    reviewStatus: reviewStatus ?? this.reviewStatus,
    author: author ?? this.author,
    dataJson: dataJson ?? this.dataJson,
  );
  QuestionRow copyWithCompanion(QuestionsCompanion data) {
    return QuestionRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      paper: data.paper.present ? data.paper.value : this.paper,
      topic: data.topic.present ? data.topic.value : this.topic,
      subtopic: data.subtopic.present ? data.subtopic.value : this.subtopic,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      marksWeight: data.marksWeight.present
          ? data.marksWeight.value
          : this.marksWeight,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      instructionBn: data.instructionBn.present
          ? data.instructionBn.value
          : this.instructionBn,
      explanationBn: data.explanationBn.present
          ? data.explanationBn.value
          : this.explanationBn,
      reviewStatus: data.reviewStatus.present
          ? data.reviewStatus.value
          : this.reviewStatus,
      author: data.author.present ? data.author.value : this.author,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('paper: $paper, ')
          ..write('topic: $topic, ')
          ..write('subtopic: $subtopic, ')
          ..write('difficulty: $difficulty, ')
          ..write('marksWeight: $marksWeight, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('instructionBn: $instructionBn, ')
          ..write('explanationBn: $explanationBn, ')
          ..write('reviewStatus: $reviewStatus, ')
          ..write('author: $author, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    paper,
    topic,
    subtopic,
    difficulty,
    marksWeight,
    tagsJson,
    instructionBn,
    explanationBn,
    reviewStatus,
    author,
    dataJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.paper == this.paper &&
          other.topic == this.topic &&
          other.subtopic == this.subtopic &&
          other.difficulty == this.difficulty &&
          other.marksWeight == this.marksWeight &&
          other.tagsJson == this.tagsJson &&
          other.instructionBn == this.instructionBn &&
          other.explanationBn == this.explanationBn &&
          other.reviewStatus == this.reviewStatus &&
          other.author == this.author &&
          other.dataJson == this.dataJson);
}

class QuestionsCompanion extends UpdateCompanion<QuestionRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> paper;
  final Value<String> topic;
  final Value<String?> subtopic;
  final Value<String> difficulty;
  final Value<double> marksWeight;
  final Value<String> tagsJson;
  final Value<String> instructionBn;
  final Value<String> explanationBn;
  final Value<String> reviewStatus;
  final Value<String> author;
  final Value<String> dataJson;
  final Value<int> rowid;
  const QuestionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.paper = const Value.absent(),
    this.topic = const Value.absent(),
    this.subtopic = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.marksWeight = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.instructionBn = const Value.absent(),
    this.explanationBn = const Value.absent(),
    this.reviewStatus = const Value.absent(),
    this.author = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionsCompanion.insert({
    required String id,
    required String type,
    required String paper,
    required String topic,
    this.subtopic = const Value.absent(),
    required String difficulty,
    required double marksWeight,
    this.tagsJson = const Value.absent(),
    required String instructionBn,
    required String explanationBn,
    required String reviewStatus,
    required String author,
    required String dataJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       paper = Value(paper),
       topic = Value(topic),
       difficulty = Value(difficulty),
       marksWeight = Value(marksWeight),
       instructionBn = Value(instructionBn),
       explanationBn = Value(explanationBn),
       reviewStatus = Value(reviewStatus),
       author = Value(author),
       dataJson = Value(dataJson);
  static Insertable<QuestionRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? paper,
    Expression<String>? topic,
    Expression<String>? subtopic,
    Expression<String>? difficulty,
    Expression<double>? marksWeight,
    Expression<String>? tagsJson,
    Expression<String>? instructionBn,
    Expression<String>? explanationBn,
    Expression<String>? reviewStatus,
    Expression<String>? author,
    Expression<String>? dataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (paper != null) 'paper': paper,
      if (topic != null) 'topic': topic,
      if (subtopic != null) 'subtopic': subtopic,
      if (difficulty != null) 'difficulty': difficulty,
      if (marksWeight != null) 'marks_weight': marksWeight,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (instructionBn != null) 'instruction_bn': instructionBn,
      if (explanationBn != null) 'explanation_bn': explanationBn,
      if (reviewStatus != null) 'review_status': reviewStatus,
      if (author != null) 'author': author,
      if (dataJson != null) 'data_json': dataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? paper,
    Value<String>? topic,
    Value<String?>? subtopic,
    Value<String>? difficulty,
    Value<double>? marksWeight,
    Value<String>? tagsJson,
    Value<String>? instructionBn,
    Value<String>? explanationBn,
    Value<String>? reviewStatus,
    Value<String>? author,
    Value<String>? dataJson,
    Value<int>? rowid,
  }) {
    return QuestionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      paper: paper ?? this.paper,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      difficulty: difficulty ?? this.difficulty,
      marksWeight: marksWeight ?? this.marksWeight,
      tagsJson: tagsJson ?? this.tagsJson,
      instructionBn: instructionBn ?? this.instructionBn,
      explanationBn: explanationBn ?? this.explanationBn,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      author: author ?? this.author,
      dataJson: dataJson ?? this.dataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (paper.present) {
      map['paper'] = Variable<String>(paper.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (subtopic.present) {
      map['subtopic'] = Variable<String>(subtopic.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (marksWeight.present) {
      map['marks_weight'] = Variable<double>(marksWeight.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (instructionBn.present) {
      map['instruction_bn'] = Variable<String>(instructionBn.value);
    }
    if (explanationBn.present) {
      map['explanation_bn'] = Variable<String>(explanationBn.value);
    }
    if (reviewStatus.present) {
      map['review_status'] = Variable<String>(reviewStatus.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('paper: $paper, ')
          ..write('topic: $topic, ')
          ..write('subtopic: $subtopic, ')
          ..write('difficulty: $difficulty, ')
          ..write('marksWeight: $marksWeight, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('instructionBn: $instructionBn, ')
          ..write('explanationBn: $explanationBn, ')
          ..write('reviewStatus: $reviewStatus, ')
          ..write('author: $author, ')
          ..write('dataJson: $dataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TopicProgressTable extends TopicProgress
    with TableInfo<$TopicProgressTable, TopicProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<int> correct = GeneratedColumn<int>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPracticedMeta = const VerificationMeta(
    'lastPracticed',
  );
  @override
  late final GeneratedColumn<DateTime> lastPracticed =
      GeneratedColumn<DateTime>(
        'last_practiced',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    topic,
    attempts,
    correct,
    lastPracticed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topic_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<TopicProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    }
    if (data.containsKey('last_practiced')) {
      context.handle(
        _lastPracticedMeta,
        lastPracticed.isAcceptableOrUnknown(
          data['last_practiced']!,
          _lastPracticedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {topic};
  @override
  TopicProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopicProgressData(
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct'],
      )!,
      lastPracticed: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_practiced'],
      ),
    );
  }

  @override
  $TopicProgressTable createAlias(String alias) {
    return $TopicProgressTable(attachedDatabase, alias);
  }
}

class TopicProgressData extends DataClass
    implements Insertable<TopicProgressData> {
  final String topic;
  final int attempts;
  final int correct;
  final DateTime? lastPracticed;
  const TopicProgressData({
    required this.topic,
    required this.attempts,
    required this.correct,
    this.lastPracticed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['topic'] = Variable<String>(topic);
    map['attempts'] = Variable<int>(attempts);
    map['correct'] = Variable<int>(correct);
    if (!nullToAbsent || lastPracticed != null) {
      map['last_practiced'] = Variable<DateTime>(lastPracticed);
    }
    return map;
  }

  TopicProgressCompanion toCompanion(bool nullToAbsent) {
    return TopicProgressCompanion(
      topic: Value(topic),
      attempts: Value(attempts),
      correct: Value(correct),
      lastPracticed: lastPracticed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPracticed),
    );
  }

  factory TopicProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopicProgressData(
      topic: serializer.fromJson<String>(json['topic']),
      attempts: serializer.fromJson<int>(json['attempts']),
      correct: serializer.fromJson<int>(json['correct']),
      lastPracticed: serializer.fromJson<DateTime?>(json['lastPracticed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'topic': serializer.toJson<String>(topic),
      'attempts': serializer.toJson<int>(attempts),
      'correct': serializer.toJson<int>(correct),
      'lastPracticed': serializer.toJson<DateTime?>(lastPracticed),
    };
  }

  TopicProgressData copyWith({
    String? topic,
    int? attempts,
    int? correct,
    Value<DateTime?> lastPracticed = const Value.absent(),
  }) => TopicProgressData(
    topic: topic ?? this.topic,
    attempts: attempts ?? this.attempts,
    correct: correct ?? this.correct,
    lastPracticed: lastPracticed.present
        ? lastPracticed.value
        : this.lastPracticed,
  );
  TopicProgressData copyWithCompanion(TopicProgressCompanion data) {
    return TopicProgressData(
      topic: data.topic.present ? data.topic.value : this.topic,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      correct: data.correct.present ? data.correct.value : this.correct,
      lastPracticed: data.lastPracticed.present
          ? data.lastPracticed.value
          : this.lastPracticed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopicProgressData(')
          ..write('topic: $topic, ')
          ..write('attempts: $attempts, ')
          ..write('correct: $correct, ')
          ..write('lastPracticed: $lastPracticed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(topic, attempts, correct, lastPracticed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopicProgressData &&
          other.topic == this.topic &&
          other.attempts == this.attempts &&
          other.correct == this.correct &&
          other.lastPracticed == this.lastPracticed);
}

class TopicProgressCompanion extends UpdateCompanion<TopicProgressData> {
  final Value<String> topic;
  final Value<int> attempts;
  final Value<int> correct;
  final Value<DateTime?> lastPracticed;
  final Value<int> rowid;
  const TopicProgressCompanion({
    this.topic = const Value.absent(),
    this.attempts = const Value.absent(),
    this.correct = const Value.absent(),
    this.lastPracticed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TopicProgressCompanion.insert({
    required String topic,
    this.attempts = const Value.absent(),
    this.correct = const Value.absent(),
    this.lastPracticed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : topic = Value(topic);
  static Insertable<TopicProgressData> custom({
    Expression<String>? topic,
    Expression<int>? attempts,
    Expression<int>? correct,
    Expression<DateTime>? lastPracticed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (topic != null) 'topic': topic,
      if (attempts != null) 'attempts': attempts,
      if (correct != null) 'correct': correct,
      if (lastPracticed != null) 'last_practiced': lastPracticed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TopicProgressCompanion copyWith({
    Value<String>? topic,
    Value<int>? attempts,
    Value<int>? correct,
    Value<DateTime?>? lastPracticed,
    Value<int>? rowid,
  }) {
    return TopicProgressCompanion(
      topic: topic ?? this.topic,
      attempts: attempts ?? this.attempts,
      correct: correct ?? this.correct,
      lastPracticed: lastPracticed ?? this.lastPracticed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (correct.present) {
      map['correct'] = Variable<int>(correct.value);
    }
    if (lastPracticed.present) {
      map['last_practiced'] = Variable<DateTime>(lastPracticed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopicProgressCompanion(')
          ..write('topic: $topic, ')
          ..write('attempts: $attempts, ')
          ..write('correct: $correct, ')
          ..write('lastPracticed: $lastPracticed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FlashcardSrsTable extends FlashcardSrs
    with TableInfo<$FlashcardSrsTable, FlashcardSrsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlashcardSrsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    questionId,
    easeFactor,
    repetitions,
    intervalDays,
    dueDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flashcard_srs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FlashcardSrsData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {questionId};
  @override
  FlashcardSrsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlashcardSrsData(
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      )!,
    );
  }

  @override
  $FlashcardSrsTable createAlias(String alias) {
    return $FlashcardSrsTable(attachedDatabase, alias);
  }
}

class FlashcardSrsData extends DataClass
    implements Insertable<FlashcardSrsData> {
  final String questionId;
  final double easeFactor;
  final int repetitions;
  final int intervalDays;
  final DateTime dueDate;
  const FlashcardSrsData({
    required this.questionId,
    required this.easeFactor,
    required this.repetitions,
    required this.intervalDays,
    required this.dueDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['question_id'] = Variable<String>(questionId);
    map['ease_factor'] = Variable<double>(easeFactor);
    map['repetitions'] = Variable<int>(repetitions);
    map['interval_days'] = Variable<int>(intervalDays);
    map['due_date'] = Variable<DateTime>(dueDate);
    return map;
  }

  FlashcardSrsCompanion toCompanion(bool nullToAbsent) {
    return FlashcardSrsCompanion(
      questionId: Value(questionId),
      easeFactor: Value(easeFactor),
      repetitions: Value(repetitions),
      intervalDays: Value(intervalDays),
      dueDate: Value(dueDate),
    );
  }

  factory FlashcardSrsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlashcardSrsData(
      questionId: serializer.fromJson<String>(json['questionId']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questionId': serializer.toJson<String>(questionId),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'repetitions': serializer.toJson<int>(repetitions),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'dueDate': serializer.toJson<DateTime>(dueDate),
    };
  }

  FlashcardSrsData copyWith({
    String? questionId,
    double? easeFactor,
    int? repetitions,
    int? intervalDays,
    DateTime? dueDate,
  }) => FlashcardSrsData(
    questionId: questionId ?? this.questionId,
    easeFactor: easeFactor ?? this.easeFactor,
    repetitions: repetitions ?? this.repetitions,
    intervalDays: intervalDays ?? this.intervalDays,
    dueDate: dueDate ?? this.dueDate,
  );
  FlashcardSrsData copyWithCompanion(FlashcardSrsCompanion data) {
    return FlashcardSrsData(
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardSrsData(')
          ..write('questionId: $questionId, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('repetitions: $repetitions, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('dueDate: $dueDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(questionId, easeFactor, repetitions, intervalDays, dueDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlashcardSrsData &&
          other.questionId == this.questionId &&
          other.easeFactor == this.easeFactor &&
          other.repetitions == this.repetitions &&
          other.intervalDays == this.intervalDays &&
          other.dueDate == this.dueDate);
}

class FlashcardSrsCompanion extends UpdateCompanion<FlashcardSrsData> {
  final Value<String> questionId;
  final Value<double> easeFactor;
  final Value<int> repetitions;
  final Value<int> intervalDays;
  final Value<DateTime> dueDate;
  final Value<int> rowid;
  const FlashcardSrsCompanion({
    this.questionId = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FlashcardSrsCompanion.insert({
    required String questionId,
    this.easeFactor = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.intervalDays = const Value.absent(),
    required DateTime dueDate,
    this.rowid = const Value.absent(),
  }) : questionId = Value(questionId),
       dueDate = Value(dueDate);
  static Insertable<FlashcardSrsData> custom({
    Expression<String>? questionId,
    Expression<double>? easeFactor,
    Expression<int>? repetitions,
    Expression<int>? intervalDays,
    Expression<DateTime>? dueDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questionId != null) 'question_id': questionId,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (repetitions != null) 'repetitions': repetitions,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (dueDate != null) 'due_date': dueDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FlashcardSrsCompanion copyWith({
    Value<String>? questionId,
    Value<double>? easeFactor,
    Value<int>? repetitions,
    Value<int>? intervalDays,
    Value<DateTime>? dueDate,
    Value<int>? rowid,
  }) {
    return FlashcardSrsCompanion(
      questionId: questionId ?? this.questionId,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      intervalDays: intervalDays ?? this.intervalDays,
      dueDate: dueDate ?? this.dueDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardSrsCompanion(')
          ..write('questionId: $questionId, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('repetitions: $repetitions, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('dueDate: $dueDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetaTable extends Meta with TableInfo<$MetaTable, MetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $MetaTable createAlias(String alias) {
    return $MetaTable(attachedDatabase, alias);
  }
}

class MetaData extends DataClass implements Insertable<MetaData> {
  final String key;
  final String value;
  const MetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaCompanion toCompanion(bool nullToAbsent) {
    return MetaCompanion(key: Value(key), value: Value(value));
  }

  factory MetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaData copyWith({String? key, String? value}) =>
      MetaData(key: key ?? this.key, value: value ?? this.value);
  MetaData copyWithCompanion(MetaCompanion data) {
    return MetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaData && other.key == this.key && other.value == this.value);
}

class MetaCompanion extends UpdateCompanion<MetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $QuestionsTable questions = $QuestionsTable(this);
  late final $TopicProgressTable topicProgress = $TopicProgressTable(this);
  late final $FlashcardSrsTable flashcardSrs = $FlashcardSrsTable(this);
  late final $MetaTable meta = $MetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    questions,
    topicProgress,
    flashcardSrs,
    meta,
  ];
}

typedef $$QuestionsTableCreateCompanionBuilder =
    QuestionsCompanion Function({
      required String id,
      required String type,
      required String paper,
      required String topic,
      Value<String?> subtopic,
      required String difficulty,
      required double marksWeight,
      Value<String> tagsJson,
      required String instructionBn,
      required String explanationBn,
      required String reviewStatus,
      required String author,
      required String dataJson,
      Value<int> rowid,
    });
typedef $$QuestionsTableUpdateCompanionBuilder =
    QuestionsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> paper,
      Value<String> topic,
      Value<String?> subtopic,
      Value<String> difficulty,
      Value<double> marksWeight,
      Value<String> tagsJson,
      Value<String> instructionBn,
      Value<String> explanationBn,
      Value<String> reviewStatus,
      Value<String> author,
      Value<String> dataJson,
      Value<int> rowid,
    });

class $$QuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paper => $composableBuilder(
    column: $table.paper,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtopic => $composableBuilder(
    column: $table.subtopic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get marksWeight => $composableBuilder(
    column: $table.marksWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructionBn => $composableBuilder(
    column: $table.instructionBn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanationBn => $composableBuilder(
    column: $table.explanationBn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewStatus => $composableBuilder(
    column: $table.reviewStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paper => $composableBuilder(
    column: $table.paper,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtopic => $composableBuilder(
    column: $table.subtopic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get marksWeight => $composableBuilder(
    column: $table.marksWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructionBn => $composableBuilder(
    column: $table.instructionBn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanationBn => $composableBuilder(
    column: $table.explanationBn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewStatus => $composableBuilder(
    column: $table.reviewStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get paper =>
      $composableBuilder(column: $table.paper, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get subtopic =>
      $composableBuilder(column: $table.subtopic, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<double> get marksWeight => $composableBuilder(
    column: $table.marksWeight,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get instructionBn => $composableBuilder(
    column: $table.instructionBn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanationBn => $composableBuilder(
    column: $table.explanationBn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewStatus => $composableBuilder(
    column: $table.reviewStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);
}

class $$QuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuestionsTable,
          QuestionRow,
          $$QuestionsTableFilterComposer,
          $$QuestionsTableOrderingComposer,
          $$QuestionsTableAnnotationComposer,
          $$QuestionsTableCreateCompanionBuilder,
          $$QuestionsTableUpdateCompanionBuilder,
          (
            QuestionRow,
            BaseReferences<_$AppDatabase, $QuestionsTable, QuestionRow>,
          ),
          QuestionRow,
          PrefetchHooks Function()
        > {
  $$QuestionsTableTableManager(_$AppDatabase db, $QuestionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> paper = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<String?> subtopic = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<double> marksWeight = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String> instructionBn = const Value.absent(),
                Value<String> explanationBn = const Value.absent(),
                Value<String> reviewStatus = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionsCompanion(
                id: id,
                type: type,
                paper: paper,
                topic: topic,
                subtopic: subtopic,
                difficulty: difficulty,
                marksWeight: marksWeight,
                tagsJson: tagsJson,
                instructionBn: instructionBn,
                explanationBn: explanationBn,
                reviewStatus: reviewStatus,
                author: author,
                dataJson: dataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String paper,
                required String topic,
                Value<String?> subtopic = const Value.absent(),
                required String difficulty,
                required double marksWeight,
                Value<String> tagsJson = const Value.absent(),
                required String instructionBn,
                required String explanationBn,
                required String reviewStatus,
                required String author,
                required String dataJson,
                Value<int> rowid = const Value.absent(),
              }) => QuestionsCompanion.insert(
                id: id,
                type: type,
                paper: paper,
                topic: topic,
                subtopic: subtopic,
                difficulty: difficulty,
                marksWeight: marksWeight,
                tagsJson: tagsJson,
                instructionBn: instructionBn,
                explanationBn: explanationBn,
                reviewStatus: reviewStatus,
                author: author,
                dataJson: dataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuestionsTable,
      QuestionRow,
      $$QuestionsTableFilterComposer,
      $$QuestionsTableOrderingComposer,
      $$QuestionsTableAnnotationComposer,
      $$QuestionsTableCreateCompanionBuilder,
      $$QuestionsTableUpdateCompanionBuilder,
      (
        QuestionRow,
        BaseReferences<_$AppDatabase, $QuestionsTable, QuestionRow>,
      ),
      QuestionRow,
      PrefetchHooks Function()
    >;
typedef $$TopicProgressTableCreateCompanionBuilder =
    TopicProgressCompanion Function({
      required String topic,
      Value<int> attempts,
      Value<int> correct,
      Value<DateTime?> lastPracticed,
      Value<int> rowid,
    });
typedef $$TopicProgressTableUpdateCompanionBuilder =
    TopicProgressCompanion Function({
      Value<String> topic,
      Value<int> attempts,
      Value<int> correct,
      Value<DateTime?> lastPracticed,
      Value<int> rowid,
    });

class $$TopicProgressTableFilterComposer
    extends Composer<_$AppDatabase, $TopicProgressTable> {
  $$TopicProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPracticed => $composableBuilder(
    column: $table.lastPracticed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TopicProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $TopicProgressTable> {
  $$TopicProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPracticed => $composableBuilder(
    column: $table.lastPracticed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TopicProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $TopicProgressTable> {
  $$TopicProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPracticed => $composableBuilder(
    column: $table.lastPracticed,
    builder: (column) => column,
  );
}

class $$TopicProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TopicProgressTable,
          TopicProgressData,
          $$TopicProgressTableFilterComposer,
          $$TopicProgressTableOrderingComposer,
          $$TopicProgressTableAnnotationComposer,
          $$TopicProgressTableCreateCompanionBuilder,
          $$TopicProgressTableUpdateCompanionBuilder,
          (
            TopicProgressData,
            BaseReferences<
              _$AppDatabase,
              $TopicProgressTable,
              TopicProgressData
            >,
          ),
          TopicProgressData,
          PrefetchHooks Function()
        > {
  $$TopicProgressTableTableManager(_$AppDatabase db, $TopicProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopicProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> topic = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> correct = const Value.absent(),
                Value<DateTime?> lastPracticed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TopicProgressCompanion(
                topic: topic,
                attempts: attempts,
                correct: correct,
                lastPracticed: lastPracticed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String topic,
                Value<int> attempts = const Value.absent(),
                Value<int> correct = const Value.absent(),
                Value<DateTime?> lastPracticed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TopicProgressCompanion.insert(
                topic: topic,
                attempts: attempts,
                correct: correct,
                lastPracticed: lastPracticed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TopicProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TopicProgressTable,
      TopicProgressData,
      $$TopicProgressTableFilterComposer,
      $$TopicProgressTableOrderingComposer,
      $$TopicProgressTableAnnotationComposer,
      $$TopicProgressTableCreateCompanionBuilder,
      $$TopicProgressTableUpdateCompanionBuilder,
      (
        TopicProgressData,
        BaseReferences<_$AppDatabase, $TopicProgressTable, TopicProgressData>,
      ),
      TopicProgressData,
      PrefetchHooks Function()
    >;
typedef $$FlashcardSrsTableCreateCompanionBuilder =
    FlashcardSrsCompanion Function({
      required String questionId,
      Value<double> easeFactor,
      Value<int> repetitions,
      Value<int> intervalDays,
      required DateTime dueDate,
      Value<int> rowid,
    });
typedef $$FlashcardSrsTableUpdateCompanionBuilder =
    FlashcardSrsCompanion Function({
      Value<String> questionId,
      Value<double> easeFactor,
      Value<int> repetitions,
      Value<int> intervalDays,
      Value<DateTime> dueDate,
      Value<int> rowid,
    });

class $$FlashcardSrsTableFilterComposer
    extends Composer<_$AppDatabase, $FlashcardSrsTable> {
  $$FlashcardSrsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FlashcardSrsTableOrderingComposer
    extends Composer<_$AppDatabase, $FlashcardSrsTable> {
  $$FlashcardSrsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FlashcardSrsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlashcardSrsTable> {
  $$FlashcardSrsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);
}

class $$FlashcardSrsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlashcardSrsTable,
          FlashcardSrsData,
          $$FlashcardSrsTableFilterComposer,
          $$FlashcardSrsTableOrderingComposer,
          $$FlashcardSrsTableAnnotationComposer,
          $$FlashcardSrsTableCreateCompanionBuilder,
          $$FlashcardSrsTableUpdateCompanionBuilder,
          (
            FlashcardSrsData,
            BaseReferences<_$AppDatabase, $FlashcardSrsTable, FlashcardSrsData>,
          ),
          FlashcardSrsData,
          PrefetchHooks Function()
        > {
  $$FlashcardSrsTableTableManager(_$AppDatabase db, $FlashcardSrsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlashcardSrsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlashcardSrsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlashcardSrsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> questionId = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FlashcardSrsCompanion(
                questionId: questionId,
                easeFactor: easeFactor,
                repetitions: repetitions,
                intervalDays: intervalDays,
                dueDate: dueDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String questionId,
                Value<double> easeFactor = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                required DateTime dueDate,
                Value<int> rowid = const Value.absent(),
              }) => FlashcardSrsCompanion.insert(
                questionId: questionId,
                easeFactor: easeFactor,
                repetitions: repetitions,
                intervalDays: intervalDays,
                dueDate: dueDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FlashcardSrsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlashcardSrsTable,
      FlashcardSrsData,
      $$FlashcardSrsTableFilterComposer,
      $$FlashcardSrsTableOrderingComposer,
      $$FlashcardSrsTableAnnotationComposer,
      $$FlashcardSrsTableCreateCompanionBuilder,
      $$FlashcardSrsTableUpdateCompanionBuilder,
      (
        FlashcardSrsData,
        BaseReferences<_$AppDatabase, $FlashcardSrsTable, FlashcardSrsData>,
      ),
      FlashcardSrsData,
      PrefetchHooks Function()
    >;
typedef $$MetaTableCreateCompanionBuilder =
    MetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$MetaTableUpdateCompanionBuilder =
    MetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$MetaTableFilterComposer extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetaTableOrderingComposer extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$MetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetaTable,
          MetaData,
          $$MetaTableFilterComposer,
          $$MetaTableOrderingComposer,
          $$MetaTableAnnotationComposer,
          $$MetaTableCreateCompanionBuilder,
          $$MetaTableUpdateCompanionBuilder,
          (MetaData, BaseReferences<_$AppDatabase, $MetaTable, MetaData>),
          MetaData,
          PrefetchHooks Function()
        > {
  $$MetaTableTableManager(_$AppDatabase db, $MetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => MetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetaTable,
      MetaData,
      $$MetaTableFilterComposer,
      $$MetaTableOrderingComposer,
      $$MetaTableAnnotationComposer,
      $$MetaTableCreateCompanionBuilder,
      $$MetaTableUpdateCompanionBuilder,
      (MetaData, BaseReferences<_$AppDatabase, $MetaTable, MetaData>),
      MetaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db, _db.questions);
  $$TopicProgressTableTableManager get topicProgress =>
      $$TopicProgressTableTableManager(_db, _db.topicProgress);
  $$FlashcardSrsTableTableManager get flashcardSrs =>
      $$FlashcardSrsTableTableManager(_db, _db.flashcardSrs);
  $$MetaTableTableManager get meta => $$MetaTableTableManager(_db, _db.meta);
}
