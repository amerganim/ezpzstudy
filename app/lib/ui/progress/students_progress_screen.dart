import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/sync_service.dart';
import '../../l10n/strings_bn.dart';
import '../../l10n/topic_labels.dart';
import '../../theme/app_theme.dart';

/// Every student's progress — openable by anyone (teacher, parent) with NO
/// login. Ranked by this week's points, and taps into a per-student breakdown.
class StudentsProgressScreen extends StatefulWidget {
  const StudentsProgressScreen({super.key});

  @override
  State<StudentsProgressScreen> createState() => _StudentsProgressScreenState();
}

class _StudentsProgressScreenState extends State<StudentsProgressScreen> {
  late Future<List<RosterStudent>> _future;
  SyncService get _sync => AppServices.of(context).sync;

  @override
  void initState() {
    super.initState();
    _future = _sync.allStudents();
  }

  Future<void> _reload() async {
    setState(() => _future = _sync.allStudents());
    await _future.catchError((_) => <RosterStudent>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Bn.allStudentsTitle)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<RosterStudent>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _CenteredRetry(onRetry: _reload);
            }
            final students = snap.data ?? const [];
            if (students.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(Bn.noStudentsAnywhere,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.black54)),
                  ),
                ],
              );
            }
            return ListView(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
              children: [
                Text('${Bn.digits(students.length)} ${Bn.studentsUnit}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 12),
                for (var i = 0; i < students.length; i++)
                  _StudentTile(rank: i + 1, s: students[i]),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final int rank;
  final RosterStudent s;
  const _StudentTile({required this.rank, required this.s});

  @override
  Widget build(BuildContext context) {
    final practiced = s.attempts > 0;
    final phone = (s.phone ?? '').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
            child: Text(Bn.digits(rank),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppTheme.accentDark)),
          ),
          title: Text(
            (s.name == null || s.name!.trim().isEmpty)
                ? 'শিক্ষার্থী'
                : s.name!.trim(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              [
                if (phone.isNotEmpty) phone,
                if (practiced)
                  '${Bn.digits(s.attempts)} ${Bn.attemptsShort} • '
                      '${s.accuracy == null ? '-' : '${Bn.digits(s.accuracy!)}%'} ${Bn.accuracyShort} • '
                      '${Bn.digits(s.weeklyPoints)} ${Bn.pointsShort}'
                else
                  Bn.neverPracticed,
              ].join('\n'),
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

class _CenteredRetry extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _CenteredRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.wifi_off, size: 48, color: Colors.black38),
        const SizedBox(height: 12),
        const Text(Bn.couldNotLoad,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54)),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            child: const Text(Bn.retry),
          ),
        ),
      ],
    );
  }
}

/// One student's per-topic breakdown, so anyone can see exactly where a student
/// is weak. Public — no login.
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
                onPressed: () => setState(
                    () => _future = _sync.studentDetail(widget.studentId)),
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
            _stat(d.accuracy == null ? '-' : '${Bn.digits(d.accuracy!)}%',
                Bn.accuracyShort),
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
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accentDark)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Text(
                '${Bn.digits(t.correct)}/${Bn.digits(t.attempts)}'
                '${t.accuracy == null ? '' : '  (${Bn.digits(t.accuracy!)}%)'}',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color),
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
