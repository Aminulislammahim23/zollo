import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/features/orders/domain/models/order_model.dart';
import 'package:zollo/features/orders/presentation/providers/order_provider.dart';
import 'package:zollo/features/orders/presentation/screens/order_details_screen.dart';
import 'package:zollo/features/orders/presentation/screens/order_history_screen.dart';
import 'package:zollo/features/products/presentation/providers/products_provider.dart';
import 'package:zollo/features/reviews/providers/review_providers.dart';
import 'package:zollo/features/tracking/domain/tracking_event_model.dart';
import 'package:zollo/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:zollo/features/tracking/presentation/widgets/tracking_timeline.dart';
import 'package:zollo/features/tracking/providers/tracking_provider.dart';

import '../../support/test_helpers.dart';
import '../../workflow_test.dart' show FakeOrderRepository;

OrderModel _order(String id, OrderStatus status, {int items = 1}) => OrderModel(
      id: id,
      userId: 'user-1',
      items: [
        for (var i = 0; i < items; i++)
          OrderItem(productId: 'p$i', productName: 'Product $i', price: 500, quantity: 1),
      ],
      shippingAddress: 'Rahim · 01712345678\nHouse 12, Dhanmondi, Dhaka',
      shippingFee: 60,
      status: status,
      createdAt: DateTime(2026, 10, 13),
    );

void main() {
  final orders = [
    _order('aaaaaa-1', OrderStatus.pending, items: 2),
    _order('bbbbbb-2', OrderStatus.shipped),
    _order('cccccc-3', OrderStatus.delivered),
  ];

  final routes = <RouteBase>[
    GoRoute(path: '/orders', builder: (_, s) => OrderHistoryScreen(initialTab: OrderTab.fromQuery(s.uri.queryParameters['tab']))),
    GoRoute(path: '/order-details/:id', builder: (_, s) => OrderDetailsScreen(orderId: s.pathParameters['id']!)),
    GoRoute(path: '/tracking/:id', builder: (_, s) => TrackingScreen(orderId: s.pathParameters['id']!)),
    stubRoute('/home'),
    stubRoute('/account'),
    stubRoute('/order-history'),
    stubRoute('/messages'),
    stubRoute('/write-review'),
    stubRoute('/return-request', 'Return destination'),
  ];

  final overrides = [
    orderRepositoryProvider.overrideWithValue(FakeOrderRepository([...orders])),
    productsProvider.overrideWith((ref) async => []),
    canUserReviewProvider.overrideWith((ref, id) async => false),
    shipmentsByOrderProvider.overrideWith((ref, id) async => <Shipment>[]),
  ];

  testWidgets('history filters orders by tab', (tester) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/orders', user: FakeUser(), overrides: overrides);
    await tester.pumpAndSettle();

    expect(find.text('Product 0 + 1 more'), findsOneWidget);
    expect(find.text('Track'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Delivered'));
    await tester.pumpAndSettle();
    expect(find.text('#ZL-CCCCCC'), findsOneWidget);
    expect(find.text('#ZL-AAAAAA'), findsNothing);
  });

  testWidgets('history opens on the tab from the query', (tester) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/orders?tab=shipped', user: FakeUser(), overrides: overrides);
    await tester.pumpAndSettle();
    expect(find.text('#ZL-BBBBBB'), findsOneWidget);
    expect(find.text('#ZL-AAAAAA'), findsNothing);
  });

  testWidgets('delivered order details offer a return', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpRoutes(tester, routes: routes, initialLocation: '/order-details/cccccc-3', user: FakeUser(), overrides: overrides);
    await tester.pumpAndSettle();

    expect(find.text('Delivered'), findsWidgets);
    expect(find.text('৳560'), findsOneWidget);
    await tester.tap(find.text('Request a return'));
    await tester.pumpAndSettle();
    expect(find.text('Return destination'), findsOneWidget);
  });

  testWidgets('tracking derives steps from the order status', (tester) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/tracking/bbbbbb-2', user: FakeUser(), overrides: overrides);
    await tester.pumpAndSettle();

    expect(find.text('Preparing your order'), findsOneWidget);
    expect(find.text('Out for delivery'), findsOneWidget);
    expect(find.text('Chat with seller'), findsOneWidget);
  });

  test('timeline steps follow the status and handle cancellation', () {
    final shipped = TimelineStep.fromOrder(_order('x', OrderStatus.shipped));
    expect(shipped.map((s) => s.state).toList(), [
      TimelineStepState.done,
      TimelineStepState.done,
      TimelineStepState.done,
      TimelineStepState.current,
      TimelineStepState.todo,
      TimelineStepState.todo,
    ]);

    final cancelled = TimelineStep.fromOrder(_order('y', OrderStatus.cancelled));
    expect(cancelled.single.state, TimelineStepState.cancelled);
  });
}
