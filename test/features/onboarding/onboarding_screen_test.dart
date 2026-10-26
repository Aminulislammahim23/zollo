import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zollo/features/auth/domain/providers/auth_provider.dart';
import 'package:zollo/features/onboarding/data/onboarding_repository.dart';
import 'package:zollo/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:zollo/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingScreen Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createOnboardingWidget({
      required GoRouter router,
    }) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserProvider.overrideWithValue(null),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('renders first page correctly (Discover Products)', (tester) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(body: Text('Login Screen')),
          ),
        ],
      );

      await tester.pumpWidget(createOnboardingWidget(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Discover Products'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Next button navigates through pages to Get Started', (tester) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(body: Text('Login Screen')),
          ),
        ],
      );

      await tester.pumpWidget(createOnboardingWidget(router: router));
      await tester.pumpAndSettle();

      // Page 1 -> Page 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Shop with Confidence'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Page 2 -> Page 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Fast & Easy Checkout'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Tapping Get Started completes onboarding and navigates to Login', (tester) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(body: Text('Login Screen')),
          ),
        ],
      );

      await tester.pumpWidget(createOnboardingWidget(router: router));
      await tester.pumpAndSettle();

      // Navigate to page 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Tap Get Started
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);

      // Verify SharedPreferences persisted onboarding_completed = true
      final repo = OnboardingRepository(prefs);
      expect(await repo.isOnboardingCompleted(), true);
    });

    testWidgets('Tapping Skip completes onboarding and navigates immediately', (tester) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(body: Text('Login Screen')),
          ),
        ],
      );

      await tester.pumpWidget(createOnboardingWidget(router: router));
      await tester.pumpAndSettle();

      // Tap Skip on page 1
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);

      final repo = OnboardingRepository(prefs);
      expect(await repo.isOnboardingCompleted(), true);
    });
  });
}
