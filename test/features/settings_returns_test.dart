import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zollo/features/orders/domain/models/order_model.dart';
import 'package:zollo/features/products/presentation/providers/products_provider.dart';
import 'package:zollo/features/returns/data/return_repository.dart';
import 'package:zollo/features/returns/domain/return_request.dart';
import 'package:zollo/features/returns/presentation/providers/return_providers.dart';
import 'package:zollo/features/returns/presentation/screens/return_request_screen.dart';
import 'package:zollo/features/settings/data/settings_repository.dart';
import 'package:zollo/features/settings/presentation/screens/settings_screen.dart';

import '../support/test_helpers.dart';

void main() {
  final order = OrderModel(
    id: 'order-1',
    userId: 'user-1',
    items: const [
      OrderItem(
        productId: 'p1',
        productName: 'Earbuds',
        price: 1850,
        quantity: 1,
      ),
      OrderItem(
        productId: 'p2',
        productName: 'Charger',
        price: 650,
        quantity: 1,
      ),
    ],
    shippingAddress: 'Rahim · 017\nDhanmondi',
    shippingFee: 60,
    status: OrderStatus.delivered,
    createdAt: DateTime(2026, 10, 10),
  );

  final routes = <RouteBase>[
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(
      path: '/return',
      builder: (_, _) => ReturnRequestScreen(order: order),
    ),
    stubRoute('/login', 'Login destination'),
    stubRoute('/settings/change-password', 'Change password destination'),
    stubRoute('/account'),
    stubRoute('/order-history'),
  ];

  testWidgets('settings saves language and notification toggles', (
    tester,
  ) async {
    await pumpRoutes(
      tester,
      routes: routes,
      initialLocation: '/settings',
      user: FakeUser(),
    );

    await tester.tap(find.text('বাংলা'));
    await tester.pump();
    await tester.tap(find.byType(Switch).first);
    await tester.pump();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SettingsRepository.localeKey), 'bn');
    expect(prefs.getBool(NotificationPref.orderUpdates.key), isFalse);
  });

  testWidgets('settings logs out to the login screen', (tester) async {
    useTallViewport(tester);
    final auth = FakeAuthRepository(user: FakeUser());
    await pumpRoutes(
      tester,
      routes: routes,
      initialLocation: '/settings',
      auth: auth,
    );

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(auth.calls, ['signOut']);
    expect(find.text('Login destination'), findsOneWidget);
  });

  testWidgets('delete account explains how to contact support', (tester) async {
    useTallViewport(tester);
    await pumpRoutes(
      tester,
      routes: routes,
      initialLocation: '/settings',
      user: FakeUser(),
    );
    await tester.tap(find.text('Delete my account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Contact support to delete your account'), findsOneWidget);
  });

  testWidgets('return request needs items and a reason', (tester) async {
    useTallViewport(tester);

    final repo = FakeReturnRepository();
    await pumpRoutes(
      tester,
      routes: routes,
      initialLocation: '/return',
      user: FakeUser(),
      overrides: [
        returnRepositoryProvider.overrideWithValue(repo),
        productsProvider.overrideWith((ref) async => []),
      ],
    );

    await tester.tap(find.text('Submit return request'));
    await tester.pump();
    expect(find.text('Choose at least one item to return.'), findsOneWidget);

    await tester.tap(find.text('Earbuds'));
    await tester.tap(find.text('Wrong item received'));
    await tester.pump();
    await tester.tap(find.text('Submit return request'));
    await tester.pump();

    expect(repo.submitted.single.productIds, ['p1']);
    expect(repo.submitted.single.reason, ReturnReason.wrongItem);
  });
}
