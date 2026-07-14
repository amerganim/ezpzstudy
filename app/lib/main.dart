import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_services.dart';
import 'config/supabase_config.dart';
import 'l10n/strings_bn.dart';
import 'theme/app_theme.dart';
import 'ui/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Connect to Supabase (backend: DB + auth + RPC). Never blocks practice —
  // the app is fully usable offline; only sync/leaderboard/teacher features
  // need the network.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    // The project's JWT anon key (publishable). `anonKey` is the correct param
    // for this key format; the deprecation points to a newer key type we don't use.
    // ignore: deprecated_member_use
    anonKey: SupabaseConfig.anonKey,
  );
  final services = AppServices.create();
  await services.initialize();
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
