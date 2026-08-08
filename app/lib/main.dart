import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_services.dart';
import 'config/supabase_config.dart';
import 'l10n/strings_bn.dart';
import 'theme/app_theme.dart';
import 'ui/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The local content DB is required for practice — gate startup on it.
  final services = AppServices.create();
  await services.initialize();

  // Connect to Supabase (backend: DB + auth + RPC). This must NEVER block the
  // app from starting: practice is fully offline, and only sync/leaderboard/
  // "see all students" need the network. Time-boxed + guarded so a slow or
  // unreachable network (common in a village pilot) can't hang the splash.
  unawaited(
    Supabase.initialize(
      url: SupabaseConfig.url,
      // The project's JWT anon key (publishable). `anonKey` is the correct param
      // for this key format; the deprecation points to a newer key type we don't use.
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
    ).timeout(const Duration(seconds: 15)).catchError((_) {
      // Offline / slow network — sync features simply stay unavailable until a
      // later attempt succeeds. Practice is unaffected.
      return Supabase.instance;
    }),
  );

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
