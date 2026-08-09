import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;

import 'app_services.dart';
import 'l10n/strings_bn.dart';
import 'theme/app_theme.dart';
import 'ui/home/home_screen.dart';

/// Loads the bundled Bengali font into the engine BEFORE the first frame, so
/// CanvasKit (web) never paints Bangla text as ▯ boxes while a font downloads.
/// Never fatal — if it fails, the font still loads lazily.
Future<void> _preloadFonts() async {
  try {
    final loader = FontLoader('HindSiliguri')
      ..addFont(rootBundle.load('fonts/HindSiliguri-Regular.ttf'))
      ..addFont(rootBundle.load('fonts/HindSiliguri-SemiBold.ttf'))
      ..addFont(rootBundle.load('fonts/HindSiliguri-Bold.ttf'));
    await loader.load();
  } catch (_) {/* non-fatal */}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The local content DB and the Bengali font are both needed for a correct
  // first frame — load them together (in parallel) before rendering.
  final services = AppServices.create();
  await Future.wait([services.initialize(), _preloadFonts()]);

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
