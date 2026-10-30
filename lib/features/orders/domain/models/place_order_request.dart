import 'payment_method.dart';

/// One cart line sent to `place_order()`.
///
/// Only [productId] (or [variantId]) and [quantity] go to the server, which
/// reads prices and stock from the database. [productName] and [unitPrice]
/// are what the shopper saw, kept for fakes and error messages.
class PlaceOrderLine {
  final String productId;
  final String? variantId;
  final int quantity;
  final String productName;
  final double unitPrice;

  const PlaceOrderLine({
    required this.productId,
    required this.quantity,
    this.variantId,
    this.productName = '',
    this.unitPrice = 0,
  });

  Map<String, dynamic> toRpcJson() => variantId != null
      ? {'variant_id': variantId, 'quantity': quantity}
      : {'product_id': productId, 'quantity': quantity};
}

class PlaceOrderRequest {
  final List<PlaceOrderLine> items;
  final String addressId;
  final PaymentMethod paymentMethod;

  /// Created once per checkout attempt, so tapping "Place order" again
  /// after a timeout returns the same order instead of a duplicate.
  final String idempotencyKey;

  /// The delivery fee shown on the checkout screen (the server applies its own).
  final double shippingFee;

  const PlaceOrderRequest({
    required this.items,
    required this.addressId,
    required this.paymentMethod,
    required this.idempotencyKey,
    required this.shippingFee,
  });

  Map<String, dynamic> toRpcParams() => {
    'p_items': items.map((i) => i.toRpcJson()).toList(),
    'p_address_id': addressId,
    'p_payment_method': paymentMethod.dbValue,
    'p_idempotency_key': idempotencyKey,
  };
}
