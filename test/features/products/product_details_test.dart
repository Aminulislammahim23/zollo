import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/features/cart/presentation/providers/cart_provider.dart';
import 'package:zollo/features/products/domain/models/product.dart';
import 'package:zollo/features/products/presentation/screens/product_details_screen.dart';
import 'package:zollo/features/reviews/data/review_repository.dart';
import 'package:zollo/features/reviews/domain/review.dart';
import 'package:zollo/features/reviews/presentation/screens/product_reviews_screen.dart';
import 'package:zollo/features/reviews/presentation/screens/write_review_screen.dart';
import 'package:zollo/features/reviews/providers/review_providers.dart';

import '../../support/test_helpers.dart';

class FakeReviewRepository implements ReviewRepository {
  final submitted = <String>[];

  @override
  Future<List<ProductReview>> getReviews(String productId) async => [];

  @override
  Future<bool> hasUserCompletedOrderForProduct(String productId) async => true;

  @override
  Future<void> submitReview({required String productId, required int rating, String? comment}) async {
    submitted.add('$productId:$rating:$comment');
  }
}

void main() {
  final reviews = [
    ProductReview(id: 'r1', productId: 'p1', userId: 'u', rating: 5, comment: 'Great sound', createdAt: DateTime(2026, 10, 13)),
    ProductReview(id: 'r2', productId: 'p1', userId: 'u2', rating: 3, createdAt: DateTime(2026, 10, 12)),
  ];

  List<RouteBase> routes(Product product) => [
        GoRoute(path: '/details', builder: (_, _) => ProductDetailsScreen(product: product)),
        GoRoute(path: '/product-reviews', builder: (_, s) => ProductReviewsScreen(product: s.extra as Product)),
        GoRoute(path: '/write-review', builder: (_, s) => WriteReviewScreen(product: s.extra as Product)),
        stubRoute('/cart', 'Cart destination'),
        stubRoute('/home'),
        stubRoute('/login'),
      ];

  late ProviderContainer container;

  Future<void> pumpDetails(WidgetTester tester, Product product, {bool canReview = false, ReviewRepository? repo}) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpRoutes(
      tester,
      routes: routes(product),
      initialLocation: '/details',
      user: canReview ? FakeUser() : null,
      overrides: [
        productReviewsProvider.overrideWith((ref, id) async => reviews),
        canUserReviewProvider.overrideWith((ref, id) async => canReview),
        if (repo != null) reviewRepositoryProvider.overrideWithValue(repo),
      ],
    );
    await tester.pump();
    container = ProviderScope.containerOf(tester.element(find.byType(ProductDetailsScreen)));
  }

  testWidgets('shows price, rating summary and colour options', (tester) async {
    await pumpDetails(tester, sampleProduct(originalPrice: 2400));

    expect(find.text('৳1,850'), findsOneWidget);
    expect(find.text('-23%'), findsOneWidget);
    expect(find.text('See all (2)'), findsOneWidget);
    expect(find.text('4.0'), findsWidgets);

    await tester.tap(find.text('Navy'));
    await tester.pump();
    expect(find.text('Navy'), findsNWidgets(2));
  });

  testWidgets('Add to cart stores the colour; Buy now opens the cart', (tester) async {
    await pumpDetails(tester, sampleProduct());

    await tester.tap(find.text('White'));
    await tester.tap(find.text('Add to cart'));
    await tester.pump();
    expect(container.read(cartProvider)['p1']?.variant, 'Colour: White');

    await tester.tap(find.text('Buy now'));
    await tester.pumpAndSettle();
    expect(find.text('Cart destination'), findsOneWidget);
    expect(container.read(cartItemCountProvider), 1);
  });

  testWidgets('out-of-stock products show a disabled button', (tester) async {
    await pumpDetails(tester, sampleProduct(stock: 0));
    expect(find.text('Add to cart'), findsNothing);
    expect(find.text('Out of stock'), findsNWidgets(2));
  });

  testWidgets('Write a review is only offered to verified buyers', (tester) async {
    await pumpDetails(tester, sampleProduct());
    expect(find.text('Write a review'), findsNothing);
  });

  testWidgets('verified buyers can submit a review', (tester) async {
    final repo = FakeReviewRepository();
    await pumpDetails(tester, sampleProduct(), canReview: true, repo: repo);

    await tester.ensureVisible(find.text('Write a review'));
    await tester.tap(find.text('Write a review'));
    await tester.pumpAndSettle();
    expect(find.text('How would you rate it?'), findsOneWidget);

    await tester.tap(find.byTooltip('4 stars – Very good'));
    await tester.pump();
    expect(find.text('Very good'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Solid bass');
    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();
    expect(repo.submitted, ['p1:4:Solid bass']);
  });

  testWidgets('reviews screen shows the distribution and cards', (tester) async {
    await pumpDetails(tester, sampleProduct());
    await tester.ensureVisible(find.text('See all (2)'));
    await tester.tap(find.text('See all (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Ratings & reviews'), findsOneWidget);
    expect(find.text('2 ratings'), findsOneWidget);
    expect(find.text('Great sound'), findsOneWidget);
    expect(find.text('Verified buyer'), findsNWidgets(2));
  });
}
