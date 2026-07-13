import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/sync_service.dart';
import '../../l10n/strings_bn.dart';
import '../../theme/app_theme.dart';
import 'class_roster_screen.dart';
import 'teacher_login_screen.dart';

/// The teacher's home: their classes, each with a live student count and the
/// enrolment code to share. Tapping a class opens its roster.
class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  late Future<List<TeacherClass>> _future;

  SyncService get _sync => AppServices.of(context).sync;

  @override
  void initState() {
    super.initState();
    _future = _sync.teacherClasses();
  }

  void _reload() => setState(() => _future = _sync.teacherClasses());

  Future<void> _logout() async {
    await _sync.teacherLogout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TeacherLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Bn.teacherDashTitle),
        actions: [
          IconButton(
            tooltip: Bn.teacherLogout,
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<List<TeacherClass>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorRetry(onRetry: _reload);
          }
          final classes = snap.data ?? const [];
          if (classes.isEmpty) {
            return const Center(child: Text(Bn.nothingHere));
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
            children: [
              for (final c in classes) _ClassCard(cls: c, onTap: () => _open(c)),
            ],
          );
        },
      ),
    );
  }

  void _open(TeacherClass c) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClassRosterScreen(
        classId: c.id,
        className: c.name,
        enrollCode: c.enrollCode,
      ),
    ));
  }
}

class _ClassCard extends StatelessWidget {
  final TeacherClass cls;
  final VoidCallback onTap;
  const _ClassCard({required this.cls, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          title: Text(cls.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${cls.collegeName ?? ''}  •  ${Bn.digits(cls.studentCount)} ${Bn.studentsUnit}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          trailing: _CodeChip(code: cls.enrollCode),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  final String code;
  const _CodeChip({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(code,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppTheme.accentDark)),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(Bn.couldNotLoad,
              style: TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text(Bn.retry)),
        ],
      ),
    );
  }
}
