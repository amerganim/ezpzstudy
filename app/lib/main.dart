import 'package:flutter/material.dart';

import 'app_services.dart';
import 'l10n/strings_bn.dart';
import 'theme/app_theme.dart';
import 'ui/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
