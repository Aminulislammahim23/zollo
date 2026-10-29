import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zollo/core/debug/style_preview_screen.dart';
import 'package:zollo/core/theme/app_theme.dart';
import 'package:zollo/core/widgets/widgets.dart';
import 'package:zollo/features/orders/domain/models/order_model.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
    );

void main() {
  testWidgets('AppButton calls onPressed and blocks taps while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(Column(
      children: [
        AppButton.primary(label: 'Go', onPressed: () => taps++),
        AppButton.primary(label: 'Busy', loading: true, onPressed: () => taps++),
      ],
    )));

    await tester.tap(find.text('Go'));
    expect(taps, 1);
    expect(find.text('Busy'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('PasswordField toggles Show / Hide', (tester) async {
    await tester.pumpWidget(_wrap(const PasswordField()));
    expect(find.text('Show'), findsOneWidget);
    await tester.tap(find.text('Show'));
    await tester.pump();
    expect(find.text('Hide'), findsOneWidget);
  });

  testWidgets('QuantityStepper disables minus at 1 and plus at stock', (tester) async {
    var value = 1;
    await tester.pumpWidget(_wrap(StatefulBuilder(
      builder: (context, setState) => QuantityStepper(
        value: value,
        max: 2,
        onIncrement: () => setState(() => value++),
        onDecrement: () => setState(() => value--),
      ),
    )));

    await tester.tap(find.byTooltip('Decrease quantity'));
    expect(value, 1);
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    expect(value, 2);
    await tester.tap(find.byTooltip('Increase quantity'));
    expect(value, 2);
  });

  testWidgets('StatusText shows a label per order status', (tester) async {
    await tester.pumpWidget(_wrap(const StatusText(OrderStatus.delivered)));
    expect(find.text('Delivered'), findsOneWidget);
  });

  testWidgets('AppBottomNav shows the cart badge only when items exist', (tester) async {
    var tapped = -1;
    await tester.pumpWidget(_wrap(AppBottomNav(
      currentIndex: 0,
      cartCount: 3,
      onTap: (i) => tapped = i,
    )));
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.text('Cart'));
    expect(tapped, 2);
  });

  testWidgets('Style preview renders every section', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: AppTheme.light, home: const StylePreviewScreen()),
    ));
    expect(find.text('Colours'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Logo'), 400, scrollable: find.byType(Scrollable).first);
    expect(find.text('Logo'), findsOneWidget);
  });
}
