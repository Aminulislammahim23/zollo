import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/features/cart/presentation/providers/cart_provider.dart';
import 'package:zollo/features/products/presentation/providers/products_provider.dart';
import 'package:zollo/features/wishlist/presentation/screens/wishlist_screen.dart';

import '../../support/test_helpers.dart';

void main() {
  final routes = <RouteBase>[
    GoRoute(path: '/wishlist', builder: (_, _) => const WishlistScreen()),
    stubRoute('/products', 'Products destination'),
    stubRoute('/login'),
    stubRoute('/cart'),
    stubRoute('/account'),
    stubRoute('/product-details'),
  ];

  testWidgets(
    'Move to cart adds the product and removes it from the wishlist',
    (tester) async {
      final repo = FakeWishlistRepository({'p1', 'p2'});
      await pumpRoutes(
        tester,
        routes: routes,
        initialLocation: '/wishlist',
        user: FakeUser(),
        wishlist: repo,
        overrides: [
          productsProvider.overrideWith(
            (ref) async => [
              sampleProduct(id: 'p1', title: 'Earbuds'),
              sampleProduct(id: 'p2', title: 'Sold out lamp', stock: 0),
            ],
          ),
        ],
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Wishlist (2)'), findsOneWidget);
      expect(find.text('Out of stock'), findsOneWidget);

      await tester.tap(find.text('Move to cart').first);
      await tester.pump();
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(WishlistScreen)),
      );
      expect(container.read(cartItemCountProvider), 1);
      expect(repo.ids, {'p2'});
      expect(find.text('Wishlist (1)'), findsOneWidget);
    },
  );

  testWidgets('empty wishlist offers Browse products', (tester) async {
    await pumpRoutes(
      tester,
      routes: routes,
      initialLocation: '/wishlist',
      user: FakeUser(),
      overrides: [productsProvider.overrideWith((ref) async => [])],
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Your wishlist is empty'), findsOneWidget);
    await tester.tap(find.text('Browse products'));
    await tester.pumpAndSettle();
    expect(find.text('Products destination'), findsOneWidget);
  });
}
