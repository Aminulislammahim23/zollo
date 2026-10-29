import '../../../products/domain/models/product.dart';

class CartItem {
  final Product product;
  final int quantity;

  /// Chosen option shown on the cart line, e.g. "Colour: Black".
  final String? variant;

  const CartItem({required this.product, required this.quantity, this.variant});

  double get subtotal => product.price * quantity;

  CartItem copyWith({int? quantity, String? variant}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      variant: variant ?? this.variant,
    );
  }
}
