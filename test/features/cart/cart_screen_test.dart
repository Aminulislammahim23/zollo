import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/core/config/app_config.dart';
import 'package:zollo/features/cart/presentation/providers/cart_provider.dart';
import 'package:zollo/features/cart/presentation/screens/cart_screen.dart';

import '../../support/test_helpers.dart';

void main() {
  final routes = <RouteBase>[
    GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
    GoRoute(
      path: '/checkout',
      builder: (_, s) => Scaffold(
        body: Text(
          'Checkout ${(s.extra as Map)['subtotal']} + ${(s.extra as Map)['deliveryCharge']}',
        ),
      ),
    ),
    stubRoute('/home', 'Home destination'),
    stubRoute('/login'),
    stubRoute('/product-details'),
  ];

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(CartScreen)));

  testWidgets('empty cart offers Start shopping', (tester) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/cart');
    expect(find.text('Your cart is empty'), findsOneWidget);
    await tester.tap(find.text('Start shopping'));
    await tester.pumpAndSettle();
    expect(find.text('Home destination'), findsOneWidget);
  });

  testWidgets('uses the delivery fee loaded from app_config', (tester) async {
    await pumpRoutes(
      tester,
      routes: routes,
      initialLocation: '/cart',
      user: FakeUser(),
      overrides: [deliveryFeeProvider.overrideWithValue(80)],
    );
    containerOf(tester)
        .read(cartProvider.notifier)
        .addToCart(sampleProduct(stock: 3));
    await tester.pump();

    expect(find.text('৳1,930'), findsOneWidget);
    await tester.tap(find.text('Checkout (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Checkout 1850.0 + 80.0'), findsOneWidget);
  });

  testWidgets('shows items, totals with delivery and steps quantity', (
    tester,
  ) async {
    await pumpRoutes(
      tester,
      routes: routes,
      initialLocation: '/cart',
      user: FakeUser(),
    );
    containerOf(tester)
        .read(cartProvider.notifier)
        .addToCart(sampleProduct(stock: 3), variant: 'Colour: Black');
    await tester.pump();

    expect(find.text('My cart (1)'), findsOneWidget);
    expect(find.text('Colour: Black'), findsOneWidget);
    expect(find.text('৳1,910'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    expect(find.text('My cart (2)'), findsOneWidget);
    expect(find.text('৳3,760'), findsOneWidget);

    await tester.tap(find.text('Checkout (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Checkout 3700.0 + 60.0'), findsOneWidget);
  });

  testWidgets('Edit mode deletes the selected items', (tester) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/cart');
    final cart = containerOf(tester).read(cartProvider.notifier);
    cart.addToCart(sampleProduct(id: 'a', title: 'Item A'));
    cart.addToCart(sampleProduct(id: 'b', title: 'Item B'));
    await tester.pump();

    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.tap(find.text('Delete (1)'));
    await tester.pump();

    expect(find.text('Item A'), findsNothing);
    expect(find.text('Item B'), findsOneWidget);
  });

  testWidgets('guests are asked to log in at checkout', (tester) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/cart');
    containerOf(tester).read(cartProvider.notifier).addToCart(sampleProduct());
    await tester.pump();

    await tester.tap(find.text('Checkout (1)'));
    await tester.pump();
    expect(find.text('Log in to check out.'), findsOneWidget);
  });
}
