import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zollo/features/auth/domain/providers/auth_provider.dart';
import 'package:zollo/features/onboarding/data/onboarding_repository.dart';
import 'package:zollo/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:zollo/features/splash/presentation/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen Widget & Navigation Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createSplashWidget({required GoRouter router, User? fakeUser}) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserProvider.overrideWithValue(fakeUser),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets(
      'SplashScreen renders logo, title, tagline and progress indicator',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/splash',
          routes: [
            GoRoute(
              path: '/splash',
              builder: (context, state) => const SplashScreen(),
            ),
            GoRoute(
              path: '/onboarding',
              builder: (context, state) =>
                  const Scaffold(body: Text('Onboarding Screen')),
            ),
          ],
        );

        await tester.pumpWidget(createSplashWidget(router: router));
        await tester.pump(); // Initial frame

        expect(find.text('zollo'), findsOneWidget);
        expect(
          find.text('Everything you need, delivered across Bangladesh'),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 1600));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Navigates to /onboarding on first launch when onboarding incomplete',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/splash',
          routes: [
            GoRoute(
              path: '/splash',
              builder: (context, state) => const SplashScreen(),
            ),
            GoRoute(
              path: '/onboarding',
              builder: (context, state) =>
                  const Scaffold(body: Text('Onboarding Screen')),
            ),
          ],
        );

        await tester.pumpWidget(createSplashWidget(router: router));
        await tester.pump(const Duration(milliseconds: 1600));
        await tester.pumpAndSettle();

        expect(find.text('Onboarding Screen'), findsOneWidget);
      },
    );

    testWidgets('Navigates to /login for returning unauthenticated user', (
      tester,
    ) async {
      final repo = OnboardingRepository(prefs);
      await repo.setOnboardingCompleted();

      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const Scaffold(body: Text('Login Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        createSplashWidget(router: router, fakeUser: null),
      );
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });
  });
}
