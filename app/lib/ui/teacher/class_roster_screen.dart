import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/sync_service.dart';
import '../../l10n/strings_bn.dart';
import '../../l10n/topic_labels.dart';
import '../../theme/app_theme.dart';

/// The class roster: every enrolled student with their practice rollup, ranked
/// by this week's points. Shows the enrolment code to share, and opens a
/// per-student breakdown on tap.
class ClassRosterScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String enrollCode;
  const ClassRosterScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.enrollCode,
  });

  @override
  State<ClassRosterScreen> createState() => _ClassRosterScreenState();
}

class _ClassRosterScreenState extends State<ClassRosterScreen> {
  late Future<ClassRoster> _future;
  SyncService get _sync => AppServices.of(context).sync;

  @override
  void initState() {
    super.initState();
    _future = _sync.classRoster(widget.classId);
  }

  Future<void> _reload() async {
    setState(() => _future = _sync.classRoster(widget.classId));
    await _future.catchError((_) => throw StateError('shown as retry'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.className)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<ClassRoster>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final roster = snap.data;
            final students = roster?.students ?? const [];
            return ListView(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
              children: [
                _CodeBanner(code: widget.enrollCode),
                const SizedBox(height: 16),
                if (snap.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(children: [
                      const Text(Bn.couldNotLoad,
                          style: TextStyle(fontSize: 16, color: Colors.black54)),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _reload, child: const Text(Bn.retry)),
                    ]),
                  )
                else if (students.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text(Bn.noStudentsYet,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.black54)),
                  )
                else
                  for (var i = 0; i < students.length; i++)
                    _RosterTile(rank: i + 1, s: students[i]),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CodeBanner extends StatelessWidget {
  final String code;
  const _CodeBanner({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(Bn.shareCodeHint,
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(code,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: AppTheme.accentDark)),
              ],
            ),
          ),
          const Icon(Icons.group_add, color: AppTheme.accent, size: 30),
        ],
      ),
    );
  }
}

class _RosterTile extends StatelessWidget {
  final int rank;
  final RosterStudent s;
  const _RosterTile({required this.rank, required this.s});

  @override
  Widget build(BuildContext context) {
    final practiced = s.attempts > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
            child: Text(Bn.digits(rank),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppTheme.accentDark)),
          ),
          title: Text(s.name ?? 'শিক্ষার্থী',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              practiced
                  ? '${Bn.digits(s.attempts)} ${Bn.attemptsShort} • '
                      '${s.accuracy == null ? '-' : '${Bn.digits(s.accuracy!)}%'} ${Bn.accuracyShort} • '
                      '${Bn.digits(s.weeklyPoints)} ${Bn.pointsShort}'
                  : Bn.neverPracticed,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.accent),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => StudentDetailScreen(
                studentId: s.id, studentName: s.name ?? 'শিক্ষার্থী'),
          )),
        ),
      ),
    );
  }
}

/// One student's per-topic breakdown, so a teacher can see exactly where they
/// are weak.
class StudentDetailScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  const StudentDetailScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Future<StudentDetail> _future;
  SyncService get _sync => AppServices.of(context).sync;

  @override
  void initState() {
    super.initState();
    _future = _sync.studentDetail(widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.studentName)),
      body: FutureBuilder<StudentDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: OutlinedButton(
                onPressed: () =>
                    setState(() => _future = _sync.studentDetail(widget.studentId)),
                child: const Text(Bn.retry),
              ),
            );
          }
          final d = snap.data!;
          return ListView(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
            children: [
              _TotalsCard(d: d),
              const SizedBox(height: 20),
              const Text(Bn.topicBreakdown,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              if (d.topics.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(Bn.noPracticeData,
                      style: TextStyle(color: Colors.black54)),
                )
              else
                for (final t in d.topics) _TopicRow(t: t),
            ],
          );
        },
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final StudentDetail d;
  const _TotalsCard({required this.d});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat(Bn.digits(d.totalAttempts), Bn.attemptsShort),
            _stat(d.accuracy == null ? '-' : '${Bn.digits(d.accuracy!)}%', Bn.accuracyShort),
            _stat(Bn.digits(d.streakDays), Bn.streakDays),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.accentDark)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      );
}

class _TopicRow extends StatelessWidget {
  final TopicStat t;
  const _TopicRow({required this.t});

  @override
  Widget build(BuildContext context) {
    final acc = t.accuracy ?? 0;
    final color = acc >= 80
        ? AppTheme.correct
        : acc >= 50
            ? AppTheme.accent
            : AppTheme.incorrect;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(TopicLabels.of(t.topic),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Text(
                '${Bn.digits(t.correct)}/${Bn.digits(t.attempts)}'
                '${t.accuracy == null ? '' : '  (${Bn.digits(t.accuracy!)}%)'}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: t.attempts == 0 ? 0 : acc / 100,
              minHeight: 7,
              backgroundColor: Colors.black12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
