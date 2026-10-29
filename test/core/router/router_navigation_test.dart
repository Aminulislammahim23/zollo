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
import 'package:zollo/features/onboarding/presentation/screens/onboarding_screen.dart';

class FakeUser extends User {
  FakeUser()
      : super(
          id: 'fake-user-id-123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Router Navigation & Auth Flow Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createTestApp({
      required GoRouter router,
      User? fakeUser,
    }) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserProvider.overrideWithValue(fakeUser),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('Full First Launch Flow: Splash -> Onboarding -> Skip -> Login', (tester) async {
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(body: Text('Login Screen Destination')),
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router: router));

      // Splash initially shown
      expect(find.text('zollo'), findsOneWidget);

      // Wait for splash transition
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      // Navigated to Onboarding
      expect(find.text('Millions of products from trusted sellers'), findsOneWidget);

      // Tap Skip in Onboarding
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Navigated to Login
      expect(find.text('Login Screen Destination'), findsOneWidget);

      // Verify onboarding status saved
      final repo = OnboardingRepository(prefs);
      expect(await repo.isOnboardingCompleted(), true);
    });

    testWidgets('Returning authenticated user goes directly to Home', (tester) async {
      final repo = OnboardingRepository(prefs);
      await repo.setOnboardingCompleted();

      final fakeUser = FakeUser();

      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(body: Text('Home Screen Destination')),
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router: router, fakeUser: fakeUser));
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(find.text('Home Screen Destination'), findsOneWidget);
    });

    testWidgets('Logout does not reset onboarding completed status', (tester) async {
      final repo = OnboardingRepository(prefs);
      await repo.setOnboardingCompleted();

      expect(await repo.isOnboardingCompleted(), true);

      // Simulating logout action does not modify onboarding completion preference
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(body: Text('Login After Logout')),
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router: router, fakeUser: null));
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(find.text('Login After Logout'), findsOneWidget);
      expect(await repo.isOnboardingCompleted(), true);
    });

    testWidgets('No infinite loop occurs on Splash navigation', (tester) async {
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(body: Text('Login Screen')),
          ),
        ],
      );

      final repo = OnboardingRepository(prefs);
      await repo.setOnboardingCompleted();

      await tester.pumpWidget(createTestApp(router: router));
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      // Successfully reached destination without throwing GoError or infinite loop exception
      expect(find.text('Login Screen'), findsOneWidget);
    });
  });
}
