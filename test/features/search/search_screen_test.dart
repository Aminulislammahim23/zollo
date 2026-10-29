import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zollo/features/products/presentation/providers/products_provider.dart';
import 'package:zollo/features/search/data/search_repository.dart';
import 'package:zollo/features/search/presentation/screens/search_screen.dart';

import '../../support/test_helpers.dart';

void main() {
  final routes = <RouteBase>[
    GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
    GoRoute(
      path: '/products',
      builder: (_, s) => Scaffold(body: Text('Results for ${s.uri.queryParameters['q']}')),
    ),
    stubRoute('/home'),
  ];

  final overrides = [
    productsProvider.overrideWith((ref) async => [
          sampleProduct(id: 'p1', title: 'Wireless Earbuds'),
          sampleProduct(id: 'p2', title: 'Smart Watch'),
        ]),
  ];

  test('recent searches keep 8, newest first, without duplicates', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = LocalSearchRepository(await SharedPreferences.getInstance());
    for (var i = 0; i < 10; i++) {
      await repo.addRecent('q$i');
    }
    await repo.addRecent('Q5');
    final recent = repo.recentSearches();
    expect(recent.length, 8);
    expect(recent.first, 'Q5');
    expect(recent.where((r) => r.toLowerCase() == 'q5').length, 1);
  });

  testWidgets('shows recent and trending, and suggests products after a debounce', (tester) async {
    await pumpRoutes(
      tester,
      routes: routes,
      initialLocation: '/search',
      overrides: overrides,
      prefs: {LocalSearchRepository.recentKey: ['headphones']},
    );
    await tester.pump();

    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('headphones'), findsOneWidget);
    expect(find.text('Trending now'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'wire');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Electronics'), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Electronics'), findsOneWidget);

    await tester.tap(find.text('Electronics'));
    await tester.pumpAndSettle();
    expect(find.text('Results for Wireless Earbuds'), findsOneWidget);
  });

  testWidgets('Clear removes recent searches', (tester) async {
    await pumpRoutes(
      tester,
      routes: routes,
      initialLocation: '/search',
      overrides: overrides,
      prefs: {LocalSearchRepository.recentKey: ['headphones']},
    );
    await tester.pump();
    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(find.text('headphones'), findsNothing);
  });
}
