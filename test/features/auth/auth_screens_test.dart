import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zollo/features/auth/domain/auth_validators.dart';
import 'package:zollo/features/auth/presentation/screens/change_password_screen.dart';
import 'package:zollo/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:zollo/features/auth/presentation/screens/login_screen.dart';
import 'package:zollo/features/auth/presentation/screens/signup_screen.dart';

import '../../support/test_helpers.dart';

void main() {
  final routes = <RouteBase>[
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
    GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
    GoRoute(path: '/change', builder: (_, _) => const ChangePasswordScreen()),
    stubRoute('/home', 'Home destination'),
  ];

  group('LoginScreen', () {
    testWidgets('validates email and password before signing in', (tester) async {
      final auth = FakeAuthRepository();
      await pumpRoutes(tester, routes: routes, initialLocation: '/login', auth: auth);

      expect(find.text('Welcome back'), findsOneWidget);
      await tester.tap(find.text('Log in'));
      await tester.pump();

      expect(find.text('Enter your email'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('signs in and opens home', (tester) async {
      final auth = FakeAuthRepository();
      await pumpRoutes(tester, routes: routes, initialLocation: '/login', auth: auth);

      await tester.enterText(find.byType(TextFormField).at(0), 'rahim@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Secret123');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(auth.calls, ['signIn']);
      expect(find.text('Home destination'), findsOneWidget);
    });

    testWidgets('shows a plain-language message for wrong credentials', (tester) async {
      final auth = FakeAuthRepository(
        error: const AuthException('Invalid login credentials', code: 'invalid_credentials'),
      );
      await pumpRoutes(tester, routes: routes, initialLocation: '/login', auth: auth);

      await tester.enterText(find.byType(TextFormField).at(0), 'rahim@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong-pass');
      await tester.tap(find.text('Log in'));
      await tester.pump();
      await tester.pump();

      expect(find.text('That email and password do not match. Try again.'), findsOneWidget);
    });

    testWidgets('Continue as guest opens home', (tester) async {
      await pumpRoutes(tester, routes: routes, initialLocation: '/login');
      await tester.tap(find.text('Continue as guest'));
      await tester.pumpAndSettle();
      expect(find.text('Home destination'), findsOneWidget);
    });
  });

  group('SignupScreen', () {
    Future<void> fillForm(WidgetTester tester, {String phone = ''}) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Rahim Uddin');
      await tester.enterText(fields.at(1), 'rahim@example.com');
      await tester.enterText(fields.at(2), phone);
      await tester.enterText(fields.at(3), 'Secret123');
    }

    testWidgets('requires the terms checkbox', (tester) async {
      final auth = FakeAuthRepository();
      await pumpRoutes(tester, routes: routes, initialLocation: '/signup', auth: auth);

      await fillForm(tester);
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Please accept the terms to continue'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('saves the phone and shows the confirmation state', (tester) async {
      final auth = FakeAuthRepository(requireConfirmation: true);
      await pumpRoutes(tester, routes: routes, initialLocation: '/signup', auth: auth);

      await fillForm(tester, phone: '01712345678');
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(auth.calls, ['signUp:+8801712345678']);
      expect(find.text('Check your email'), findsOneWidget);
    });
  });

  testWidgets('ForgotPasswordScreen sends a link and shows the inbox state', (tester) async {
    final auth = FakeAuthRepository();
    await pumpRoutes(tester, routes: routes, initialLocation: '/forgot-password', auth: auth);

    await tester.enterText(find.byType(TextFormField), 'rahim@example.com');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(auth.calls, ['reset:rahim@example.com']);
    expect(find.text('Check your inbox'), findsOneWidget);
  });

  testWidgets('ChangePasswordScreen checks rules and confirmation', (tester) async {
    final auth = FakeAuthRepository(user: FakeUser());
    await pumpRoutes(tester, routes: routes, initialLocation: '/change', auth: auth);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'OldPass1');
    await tester.enterText(fields.at(1), 'NewPass12');
    await tester.enterText(fields.at(2), 'Different1');
    await tester.tap(find.text('Update password'));
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);

    await tester.enterText(fields.at(2), 'NewPass12');
    await tester.tap(find.text('Update password'));
    await tester.pump();
    expect(auth.calls, ['changePassword:false']);
  });

  test('password strength grows with length and character mix', () {
    expect(AuthValidators.strength(''), 0);
    expect(AuthValidators.strength('abc'), 1);
    expect(AuthValidators.strength('Abcdefg1!xyz'), 4);
  });
}
