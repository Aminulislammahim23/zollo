import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/features/categories/domain/category.dart';
import 'package:zollo/features/categories/presentation/providers/categories_provider.dart';
import 'package:zollo/features/home/presentation/home_screen.dart';
import 'package:zollo/features/products/presentation/providers/products_provider.dart';

import '../../support/test_helpers.dart';

void main() {
  final routes = <RouteBase>[
    GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    stubRoute('/search', 'Search destination'),
    stubRoute('/products', 'Products destination'),
    stubRoute('/categories'),
    stubRoute('/notifications'),
    stubRoute('/login'),
    stubRoute('/product-details', 'Details destination'),
  ];

  final overrides = [
    productsProvider.overrideWith((ref) async => [
          sampleProduct(id: 'p1', title: 'Earbuds', originalPrice: 2400),
          sampleProduct(id: 'p2', title: 'Keyboard', price: 4200),
          sampleProduct(id: 'p3', title: 'Smart Watch', price: 3500),
        ]),
    categoriesProvider.overrideWith((ref) async => const [
          Category(id: 'c1', name: 'Electronics'),
          Category(id: 'c2', name: 'Fashion'),
        ]),
  ];

  testWidgets('Home renders header, categories, flash sale and grid', (tester) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/home', overrides: overrides);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('zollo'), findsOneWidget);
    expect(find.text('Add a delivery address'), findsOneWidget);
    expect(find.text('Electronics'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Flash Sale'), findsOneWidget);
    expect(find.text('৳2,400'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Just for you'),
      300,
      scrollable: find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('Just for you'), findsOneWidget);
  });

  testWidgets('Search bar opens the search screen', (tester) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/home', overrides: overrides);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Search products, brands and shops'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Search destination'), findsOneWidget);
  });

  testWidgets('Shows a retry view when products fail', (tester) async {
    await pumpRoutes(
      tester,
      routes: routes,
      initialLocation: '/home',
      overrides: [
        productsProvider.overrideWith((ref) async => throw Exception('offline')),
        categoriesProvider.overrideWith((ref) async => const <Category>[]),
      ],
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("Couldn't load products"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
