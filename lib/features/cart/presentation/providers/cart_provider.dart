import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/cart_item.dart';
import '../../../products/domain/models/product.dart';

final cartProvider = NotifierProvider<CartController, Map<String, CartItem>>(
  CartController.new,
);

class CartController extends Notifier<Map<String, CartItem>> {
  @override
  Map<String, CartItem> build() => {};

  void addToCart(Product product) {
    if (product.stock <= 0) return;

    final currentItem = state[product.id];

    // Product already exists: increase quantity.
    if (currentItem != null) {
      if (currentItem.quantity >= product.stock) return;

      state = {
        ...state,
        product.id: currentItem.copyWith(quantity: currentItem.quantity + 1),
      };
      return;
    }

    // New product.
    state = {...state, product.id: CartItem(product: product, quantity: 1)};
  }

  void increment(String productId) {
    final item = state[productId];

    if (item == null) return;
    if (item.quantity >= item.product.stock) return;

    state = {...state, productId: item.copyWith(quantity: item.quantity + 1)};
  }

  void decrement(String productId) {
    final item = state[productId];

    if (item == null) return;

    if (item.quantity <= 1) {
      removeItem(productId);
      return;
    }

    state = {...state, productId: item.copyWith(quantity: item.quantity - 1)};
  }

  void removeItem(String productId) {
    final updatedCart = Map<String, CartItem>.from(state);
    updatedCart.remove(productId);
    state = updatedCart;
  }

  void clearCart() {
    state = {};
  }
}

// Derived values: calculated from the current cart state.

final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);

  return cart.values.fold<int>(0, (total, item) => total + item.quantity);
});

final cartSubtotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);

  return cart.values.fold<double>(0, (total, item) => total + item.subtotal);
});
