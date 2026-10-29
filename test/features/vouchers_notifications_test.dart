import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:zollo/features/vouchers/presentation/screens/vouchers_screen.dart';

import '../support/test_helpers.dart';

void main() {
  final routes = <RouteBase>[
    GoRoute(path: '/vouchers', builder: (_, _) => const VouchersScreen()),
    GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
    stubRoute('/account'),
    stubRoute('/home'),
    stubRoute('/products', 'Products destination'),
    stubRoute('/order-history', 'Orders destination'),
  ];

  testWidgets('vouchers list sample tickets and redeem a valid code', (tester) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/vouchers');
    await tester.pump();

    expect(find.text('৳100'), findsOneWidget);
    expect(find.text('Expires in 2 days').evaluate().isNotEmpty || find.text('Expires in 3 days').evaluate().isNotEmpty, isTrue);

    await tester.enterText(find.byType(TextFormField), 'nope');
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text("That code isn't valid or has expired."), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'zollo50');
    expect(find.text('ZOLLO50'), findsOneWidget);
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text('৳50'), findsOneWidget);
  });

  testWidgets('notifications filter by tab and mark all read', (tester) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/notifications');
    await tester.pump();

    expect(find.text('Your order is on the way'), findsOneWidget);
    expect(find.text('11.11 Mega Sale starts tonight'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Promotions'));
    await tester.pumpAndSettle();
    expect(find.text('Your order is on the way'), findsNothing);
    expect(find.text('11.11 Mega Sale starts tonight'), findsOneWidget);

    await tester.tap(find.text('Mark all read'));
    await tester.pump();
    expect(find.bySemanticsLabel('Unread'), findsNothing);

    await tester.tap(find.text('11.11 Mega Sale starts tonight'));
    await tester.pumpAndSettle();
    expect(find.text('Products destination'), findsOneWidget);
  });
}
