/// Error codes raised by the order functions in the database
/// (`place_order`, `cancel_order`), mapped to messages for shoppers.
enum OrderErrorCode {
  outOfStock(
    'OUT_OF_STOCK',
    'Part of your order just sold out. Update your cart and try again.',
  ),
  productUnavailable(
    'PRODUCT_UNAVAILABLE',
    'An item in your cart is no longer available. Remove it and try again.',
  ),
  addressNotFound(
    'ADDRESS_NOT_FOUND',
    "We couldn't find that delivery address. Choose another one.",
  ),
  emptyCart('EMPTY_CART', 'Your cart is empty.'),
  invalidQuantity(
    'INVALID_QUANTITY',
    'You can order between 1 and 99 of each item.',
  ),
  invalidPaymentMethod(
    'INVALID_PAYMENT_METHOD',
    "That payment method isn't available. Choose another one.",
  ),
  notAuthenticated(
    'NOT_AUTHENTICATED',
    'Your session has expired. Log in again to continue.',
  ),
  orderNotFound('ORDER_NOT_FOUND', "We couldn't find this order."),
  orderNotCancellable(
    'ORDER_NOT_CANCELLABLE',
    'This order is already being prepared and can no longer be cancelled.',
  );

  const OrderErrorCode(this.code, this.message);

  final String code;
  final String message;

  static OrderErrorCode? fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

class OrderException implements Exception {
  const OrderException(this.code, {this.detail});

  final OrderErrorCode code;

  /// Extra info from the database, e.g. the variant id that ran out.
  final String? detail;

  String get message => code.message;

  @override
  String toString() => message;
}
