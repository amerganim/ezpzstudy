import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/sync_service.dart';
import '../../l10n/strings_bn.dart';
import '../../theme/app_theme.dart';
import '../teacher/teacher_login_screen.dart';

/// Optional account + progress sync. Practice never requires this — a student
/// can use the whole app offline and forever without logging in. Logging in by
/// phone lets their progress survive a lost/reset phone and (later) power a
/// class leaderboard.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _enrollCode = TextEditingController();

  bool _busy = false;
  bool _loggedIn = false;
  DateTime? _lastSynced;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _enrollCode.dispose();
    super.dispose();
  }

  SyncService get _sync => AppServices.of(context).sync;

  Future<void> _refresh() async {
    final loggedIn = await _sync.isLoggedIn();
    final last = await _sync.lastSyncAt();
    if (mounted) {
      setState(() {
        _loggedIn = loggedIn;
        _lastSynced = last;
      });
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _login() async {
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      _toast(Bn.enterPhone);
      return;
    }
    setState(() => _busy = true);
    try {
      await _sync.login(
        phone: phone,
        name: _name.text.trim(),
        enrollCode: _enrollCode.text.trim(),
      );
      final outcome = await _sync.syncNow();
      _toast(_messageFor(outcome));
    } on ApiException catch (e) {
      // A wrong class code is worth naming; anything else is a friendly retry.
      final invalidCode = e.message.toLowerCase().contains('enrol');
      _toast(invalidCode ? Bn.invalidClassCode : Bn.loginError);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refresh();
    }
  }

  Future<void> _syncNow() async {
    setState(() => _busy = true);
    final outcome = await _sync.syncNow();
    _toast(_messageFor(outcome));
    if (mounted) setState(() => _busy = false);
    await _refresh();
  }

  Future<void> _logout() async {
    await _sync.logout();
    await _refresh();
  }

  String _messageFor(SyncOutcome outcome) {
    switch (outcome.status) {
      case SyncStatus.success:
        return Bn.syncSuccess;
      case SyncStatus.offline:
        return Bn.syncOffline;
      case SyncStatus.notLoggedIn:
        return Bn.syncSubtitle;
      case SyncStatus.error:
        return Bn.syncError;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Bn.syncTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).padding.bottom + 24),
        children: [
          Text(Bn.syncSubtitle,
              style: const TextStyle(fontSize: 15, color: Colors.black54)),
          const SizedBox(height: 20),
          if (_loggedIn) _loggedInView() else _loginView(),
        ],
      ),
    );
  }

  Widget _loginView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(_phone, Bn.phoneLabel, keyboard: TextInputType.phone),
        const SizedBox(height: 12),
        _field(_name, Bn.nameLabel),
        const SizedBox(height: 12),
        _field(_enrollCode, Bn.enrollCodeLabel),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _login,
          child: _busy
              ? const SizedBox(
                  height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text(Bn.loginAndSync),
        ),
        const SizedBox(height: 24),
        const Divider(),
        TextButton.icon(
          onPressed: _busy
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const TeacherLoginScreen(),
                  )),
          icon: const Icon(Icons.school_outlined),
          label: const Text(Bn.teacherLoginLink),
        ),
      ],
    );
  }

  Widget _loggedInView() {
    final last = _lastSynced;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.cloud_done, color: AppTheme.correct, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    last == null
                        ? Bn.neverSynced
                        : '${Bn.lastSynced}: ${_formatTime(last)}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _syncNow,
          child: _busy
              ? const SizedBox(
                  height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text(Bn.syncNow),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _busy ? null : _logout,
          child: const Text(Bn.logout),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}
