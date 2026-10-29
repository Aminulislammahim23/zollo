import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zollo/core/theme/app_theme.dart';
import 'package:zollo/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://iqfonuusluafcyiozfhz.supabase.co',
    ),
    publishableKey: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlxZm9udXVzbHVhZmN5aW96Zmh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI5MjgxMDQsImV4cCI6MjEwODUwNDEwNH0.TTiO8feWtNE3M6p-MP8JdEOBci6h2M1iJN2yFvdll0o',
    ),
  );

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      // Screens show an ErrorView with "Try again" instead of retrying silently.
      retry: (retryCount, error) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'zollo',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
