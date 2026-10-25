enum PaymentMethod { cashOnDelivery, online }

class CheckoutOrder {
  final String customerName;
  final String phone;
  final String address;
  final PaymentMethod paymentMethod;
  final double subtotal;
  final double deliveryCharge;

  const CheckoutOrder({
    required this.customerName,
    required this.phone,
    required this.address,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryCharge,
  });

  double get total => subtotal + deliveryCharge;
}
