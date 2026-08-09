import 'dart:async';

import 'package:flutter/material.dart';

import 'app_services.dart';
import 'l10n/strings_bn.dart';
import 'theme/app_theme.dart';
import 'ui/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The local content DB is required for practice — gate startup on it.
  final services = AppServices.create();
  await services.initialize();

  // Render immediately. The Supabase backend (auth + sync + leaderboard + roster)
  // initializes lazily in the background via SyncService: it is NEVER awaited on
  // the startup path, so a slow or unreachable mobile network can't delay or
  // break the offline-first UI. Features that need it (Save progress, See all
  // students) await readiness on demand and retry.
  unawaited(services.sync.warmUp());

  runApp(EzpzApp(services: services));
}

class EzpzApp extends StatelessWidget {
  final AppServices services;
  const EzpzApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return AppServicesScope(
      services: services,
      child: MaterialApp(
        title: Bn.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const HomeScreen(),
      ),
    );
  }
}
