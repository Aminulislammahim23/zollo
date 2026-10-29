import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/features/categories/domain/category.dart';
import 'package:zollo/features/categories/presentation/providers/categories_provider.dart';
import 'package:zollo/features/categories/presentation/screens/categories_screen.dart';
import 'package:zollo/features/products/domain/product_filter.dart';
import 'package:zollo/features/products/presentation/providers/products_provider.dart';
import 'package:zollo/features/products/presentation/screens/product_list_screen.dart';

import '../../support/test_helpers.dart';

void main() {
  final products = [
    sampleProduct(id: 'p1', title: 'Wireless Earbuds', price: 1850, rating: 4.6, categoryId: 'c1'),
    sampleProduct(id: 'p2', title: 'Cotton Panjabi', price: 2400, rating: 3.8, categoryId: 'c2', category: 'Fashion'),
    sampleProduct(id: 'p3', title: 'Mechanical Keyboard', price: 4200, rating: 4.2, categoryId: 'c1'),
  ];
  const categories = [Category(id: 'c1', name: 'Electronics'), Category(id: 'c2', name: 'Fashion')];

  group('ProductFilter', () {
    test('searches by name and filters by rating and category', () {
      expect(const ProductFilter(query: 'key').apply(products).map((p) => p.id), ['p3']);
      expect(const ProductFilter(minRating4: true).apply(products).length, 2);
      expect(const ProductFilter(categoryIds: {'c2'}).apply(products).map((p) => p.id), ['p2']);
    });

    test('sorts by price both ways and by price range', () {
      expect(
        const ProductFilter(sort: ProductSort.priceLowToHigh).apply(products).map((p) => p.id),
        ['p1', 'p2', 'p3'],
      );
      expect(
        const ProductFilter(sort: ProductSort.priceHighToLow).apply(products).first.id,
        'p3',
      );
      expect(const ProductFilter(maxPrice: 2000).apply(products).map((p) => p.id), ['p1']);
    });

    test('matches products that only carry the category name', () {
      final named = [sampleProduct(id: 'x', categoryId: '', category: 'Fashion')];
      expect(
        const ProductFilter(categoryIds: {'c2'}).apply(named, categoryNames: {'c2': 'Fashion'}).length,
        1,
      );
    });
  });

  final overrides = [
    productsProvider.overrideWith((ref) async => products),
    categoriesProvider.overrideWith((ref) async => categories),
  ];

  final routes = <RouteBase>[
    GoRoute(
      path: '/products',
      builder: (_, state) => ProductListScreen(
        categoryId: state.uri.queryParameters['category'],
        query: state.uri.queryParameters['q'],
      ),
    ),
    GoRoute(path: '/categories', builder: (_, _) => const CategoriesScreen()),
    stubRoute('/product-details'),
    stubRoute('/search'),
    stubRoute('/cart'),
    stubRoute('/home'),
  ];

  testWidgets('ProductListScreen searches live and shows the result count', (tester) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/products', overrides: overrides);
    await tester.pump();

    expect(find.text('3 results'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'earbuds');
    await tester.pump();
    expect(find.text('1 result'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nothing-matches');
    await tester.pump();
    expect(find.text('No products found'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pump();
    expect(find.text('3 results'), findsOneWidget);
  });

  testWidgets('ProductListScreen applies the category query param', (tester) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/products?category=c1', overrides: overrides);
    await tester.pump();
    expect(find.text('2 results'), findsOneWidget);

    await tester.tap(find.text('4★ & up'));
    await tester.pump();
    expect(find.text('2 results'), findsOneWidget);
  });

  testWidgets('CategoriesScreen switches category from the rail', (tester) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/categories', overrides: overrides);
    await tester.pump();

    expect(find.text('See all Electronics'), findsOneWidget);
    expect(find.text('Wireless Earbuds'), findsOneWidget);

    await tester.tap(find.text('Fashion').first);
    await tester.pump();
    await tester.pump();
    expect(find.text('See all Fashion'), findsOneWidget);
    expect(find.text('Cotton Panjabi'), findsOneWidget);
  });
}
