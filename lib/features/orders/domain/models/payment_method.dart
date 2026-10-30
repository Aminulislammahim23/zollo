/// Payment methods accepted by `place_order()`. Only cash on delivery is
/// enabled in the app for now; the others are shown as "Coming soon".
enum PaymentMethod {
  cashOnDelivery('cash_on_delivery', 'Cash on delivery'),
  bkash('bkash', 'bKash'),
  nagad('nagad', 'Nagad'),
  card('card', 'Card');

  const PaymentMethod(this.dbValue, this.label);

  /// Value stored in `orders.payment_method` / `payments.method`.
  final String dbValue;
  final String label;

  static PaymentMethod fromDb(String? value) => PaymentMethod.values.firstWhere(
    (m) => m.dbValue == value,
    orElse: () => cashOnDelivery,
  );
}
