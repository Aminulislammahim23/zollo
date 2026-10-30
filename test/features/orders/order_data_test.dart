import 'package:flutter_test/flutter_test.dart';
import 'package:zollo/features/orders/domain/models/order_model.dart';
import 'package:zollo/features/orders/domain/models/payment_method.dart';
import 'package:zollo/features/orders/domain/models/place_order_request.dart';
import 'package:zollo/features/orders/domain/order_exception.dart';

void main() {
  group('PlaceOrderRequest', () {
    test('sends only ids and quantities to place_order()', () {
      const request = PlaceOrderRequest(
        items: [
          PlaceOrderLine(
            productId: 'p1',
            quantity: 2,
            productName: 'Earbuds',
            unitPrice: 1850,
          ),
          PlaceOrderLine(productId: 'p2', variantId: 'v9', quantity: 1),
        ],
        addressId: 'a1',
        paymentMethod: PaymentMethod.cashOnDelivery,
        idempotencyKey: 'key-1',
        shippingFee: 60,
      );

      expect(request.toRpcParams(), {
        'p_items': [
          {'product_id': 'p1', 'quantity': 2},
          {'variant_id': 'v9', 'quantity': 1},
        ],
        'p_address_id': 'a1',
        'p_payment_method': 'cash_on_delivery',
        'p_idempotency_key': 'key-1',
      });
    });
  });

  group('OrderModel.fromJson', () {
    final row = {
      'id': 'o1',
      'user_id': 'u1',
      'status': 'shipped',
      'payment_method': 'cash_on_delivery',
      'shipping_name': 'Rahim Uddin',
      'shipping_phone': '01712345678',
      'shipping_address': 'House 12, Road 4, Dhanmondi, Dhaka City, Dhaka',
      'shipping_fee': 60,
      'subtotal': 3700,
      'total_amount': 3760,
      'created_at': '2026-10-30T10:00:00Z',
      'order_items': [
        {
          'product_id': 'p1',
          'product_name': 'Earbuds',
          'unit_price': 1850,
          'quantity': 2,
          'line_total': 3700,
          'image_snapshot': 'https://img/p1.jpg',
        },
      ],
    };

    test('reads embedded order_items with unit_price and line_total', () {
      final order = OrderModel.fromJson(row);
      expect(order.items.single.price, 1850);
      expect(order.items.single.subtotal, 3700);
      expect(order.items.single.imageUrl, 'https://img/p1.jpg');
      expect(order.itemCount, 2);
      expect(order.total, 3760);
      expect(order.status, OrderStatus.shipped);
      expect(order.paymentMethod, PaymentMethod.cashOnDelivery);
    });

    test('uses the separate shipping name and phone columns', () {
      final order = OrderModel.fromJson(row);
      expect(order.recipient, 'Rahim Uddin · 01712345678');
      expect(
        order.deliveryAddress,
        'House 12, Road 4, Dhanmondi, Dhaka City, Dhaka',
      );
    });

    test('still reads the old "name · phone" first-line snapshot', () {
      final order = OrderModel.fromJson({
        'id': 'o2',
        'shipping_address': 'Rahim · 017\nHouse 12, Dhaka',
      });
      expect(order.recipient, 'Rahim · 017');
      expect(order.deliveryAddress, 'House 12, Dhaka');
      expect(order.items, isEmpty);
    });
  });

  test('every database error code has a friendly message', () {
    for (final code in [
      'OUT_OF_STOCK',
      'PRODUCT_UNAVAILABLE',
      'ADDRESS_NOT_FOUND',
      'EMPTY_CART',
      'INVALID_QUANTITY',
      'INVALID_PAYMENT_METHOD',
      'NOT_AUTHENTICATED',
      'ORDER_NOT_FOUND',
      'ORDER_NOT_CANCELLABLE',
    ]) {
      final value = OrderErrorCode.fromCode(code);
      expect(value, isNotNull, reason: code);
      expect(value!.message, isNot(contains('_')), reason: code);
    }
    expect(OrderErrorCode.fromCode('something else'), isNull);
  });
}
