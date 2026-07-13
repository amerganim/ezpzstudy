import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/sync_service.dart';
import '../../l10n/strings_bn.dart';
import 'teacher_dashboard_screen.dart';

/// Teacher login (phone + password). On a teacher's own phone; students never
/// see this. If already logged in, jumps straight to the dashboard.
class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  SyncService get _sync => AppServices.of(context).sync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await _sync.isTeacherLoggedIn() && mounted) _goDashboard();
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _goDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
    );
  }

  Future<void> _login() async {
    final phone = _phone.text.trim();
    final pass = _password.text;
    if (phone.isEmpty || pass.isEmpty) return;
    setState(() => _busy = true);
    try {
      await _sync.teacherLogin(phone: phone, password: pass);
      if (mounted) _goDashboard();
    } on ApiException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(Bn.teacherLoginError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Bn.teacherLoginTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 24, 20, MediaQuery.of(context).padding.bottom + 24),
        children: [
          const Text('👩‍🏫', style: TextStyle(fontSize: 56), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: Bn.phoneLabel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: Bn.passwordLabel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _login,
            child: _busy
                ? const SizedBox(
                    height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text(Bn.teacherLoginButton),
          ),
        ],
      ),
    );
  }
}
