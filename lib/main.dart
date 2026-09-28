import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/tracker_provider.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/storage_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  await storage.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => TrackerProvider(storage),
      child: const MacroTrackApp(),
    ),
  );
}

class MacroTrackApp extends StatelessWidget {
  const MacroTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final onboarded = context.select<TrackerProvider, bool>((p) => p.onboarded);
    return MaterialApp(
      title: 'MacroTrack',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: onboarded ? const HomeShell() : const OnboardingScreen(),
    );
  }
}
