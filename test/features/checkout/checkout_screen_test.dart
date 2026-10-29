import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/features/address/domain/address_model.dart';
import 'package:zollo/features/address/presentation/providers/address_provider.dart';
import 'package:zollo/features/cart/presentation/providers/cart_provider.dart';
import 'package:zollo/features/checkout/screens/checkout_screen.dart';
import 'package:zollo/features/orders/domain/models/order_model.dart';
import 'package:zollo/features/orders/presentation/providers/order_provider.dart';
import 'package:zollo/features/orders/presentation/screens/order_confirmation_screen.dart';

import '../../support/test_helpers.dart';
import '../../workflow_test.dart' show FakeOrderRepository;

void main() {
  final address = Address(
    id: 'a1',
    userId: 'user-1',
    fullName: 'Rahim Uddin',
    phone: '01712345678',
    addressLine: 'House 12, Road 4',
    city: 'Dhaka City',
    postalCode: '1205',
    area: 'Dhanmondi',
    isDefault: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final routes = <RouteBase>[
    GoRoute(
      path: '/checkout',
      builder: (_, _) => const CheckoutScreen(subtotal: 0),
    ),
    GoRoute(
      path: '/order-confirmation',
      builder: (_, s) => OrderConfirmationScreen(order: s.extra as OrderModel),
    ),
    stubRoute('/home'),
    stubRoute('/cart'),
    stubRoute('/add-address'),
    stubRoute('/addresses'),
  ];

  testWidgets('places a COD order whose total matches the screen', (
    tester,
  ) async {
    final orders = FakeOrderRepository([]);
    await pumpRoutes(
      tester,
      routes: routes,
      initialLocation: '/checkout',
      user: FakeUser(),
      overrides: [
        defaultAddressProvider.overrideWith((ref) async => address),
        orderRepositoryProvider.overrideWithValue(orders),
      ],
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CheckoutScreen)),
    );
    container.read(cartProvider.notifier).addToCart(sampleProduct(price: 1850));
    container.read(cartProvider.notifier).increment('p1');
    await tester.pump();
    await tester.pump();

    expect(find.text('Rahim Uddin · 01712345678'), findsOneWidget);
    expect(find.text('Package 1 · 2 items'), findsOneWidget);
    expect(find.text('Coming soon'), findsNWidgets(3));
    expect(find.text('৳3,760'), findsOneWidget);

    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();

    expect(orders.orders.single.total, 3760);
    expect(orders.orders.single.shippingFee, 60);
    expect(find.text('Order placed'), findsOneWidget);
    expect(find.text('Track my order'), findsOneWidget);
    expect(container.read(cartItemCountProvider), 0);
  });

  testWidgets('asks for an address when none is saved', (tester) async {
    await pumpRoutes(
      tester,
      routes: routes,
      initialLocation: '/checkout',
      user: FakeUser(),
      overrides: [defaultAddressProvider.overrideWith((ref) async => null)],
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CheckoutScreen)),
    );
    container.read(cartProvider.notifier).addToCart(sampleProduct());
    await tester.pump();
    await tester.pump();

    expect(find.text('Add a delivery address'), findsOneWidget);
    await tester.tap(find.text('Place order'));
    await tester.pump();
    expect(
      find.text('Please select or add a delivery address.'),
      findsOneWidget,
    );
  });
}
