import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zollo/features/products/domain/models/product.dart';
import 'package:zollo/features/cart/presentation/providers/cart_provider.dart';
import 'package:zollo/features/orders/domain/models/order_model.dart';

void main() {
  group('Day 5-6: Product Model Tests', () {
    test('parses Product from JSON correctly', () {
      final json = {
        'id': '101',
        'title': 'Smart Watch',
        'description': 'Waterproof fitness smart watch',
        'price': 1999.0,
        'image': 'https://example.com/watch.png',
        'category': 'Wearables',
        'rating': {'rate': 4.7},
        'stock': 15,
      };

      final product = Product.fromJson(json);

      expect(product.id, '101');
      expect(product.title, 'Smart Watch');
      expect(product.price, 1999.0);
      expect(product.category, 'Wearables');
      expect(product.rating, 4.7);
      expect(product.stock, 15);
    });
  });

  group('Day 7: Cart System Tests', () {
    test('adds product to cart and updates subtotal and item count', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final product = const Product(
        id: '1',
        title: 'Running Shoes',
        description: 'Comfortable sports shoes',
        price: 1500.0,
        imageUrl: '',
        category: 'Footwear',
        rating: 4.8,
        stock: 5,
      );

      // Initially cart is empty
      expect(container.read(cartItemCountProvider), 0);
      expect(container.read(cartSubtotalProvider), 0.0);

      // Add to cart
      container.read(cartProvider.notifier).addToCart(product);

      expect(container.read(cartItemCountProvider), 1);
      expect(container.read(cartSubtotalProvider), 1500.0);

      // Increment quantity
      container.read(cartProvider.notifier).increment('1');
      expect(container.read(cartItemCountProvider), 2);
      expect(container.read(cartSubtotalProvider), 3000.0);

      // Decrement quantity
      container.read(cartProvider.notifier).decrement('1');
      expect(container.read(cartItemCountProvider), 1);
      expect(container.read(cartSubtotalProvider), 1500.0);

      // Remove item
      container.read(cartProvider.notifier).removeItem('1');
      expect(container.read(cartItemCountProvider), 0);
      expect(container.read(cartSubtotalProvider), 0.0);
    });

    test('clears cart successfully', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final product = const Product(
        id: '2',
        title: 'Backpack',
        description: 'Laptop backpack',
        price: 1200.0,
        imageUrl: '',
        category: 'Accessories',
        rating: 4.2,
        stock: 10,
      );

      container.read(cartProvider.notifier).addToCart(product);
      expect(container.read(cartItemCountProvider), 1);

      container.read(cartProvider.notifier).clearCart();
      expect(container.read(cartItemCountProvider), 0);
      expect(container.read(cartSubtotalProvider), 0.0);
    });
  });

  group('Day 8-9: Order Model & Calculations Tests', () {
    test('calculates order item subtotal and order total correctly', () {
      final orderItem = const OrderItem(
        productId: '1',
        productName: 'T-Shirt',
        price: 500.0,
        quantity: 3,
      );

      expect(orderItem.subtotal, 1500.0);

      final order = OrderModel(
        id: 'order-uuid-123',
        userId: 'user-uuid-456',
        items: [orderItem],
        shippingAddress: 'Dhaka, Bangladesh',
        shippingFee: 60.0,
        status: OrderStatus.pending,
        createdAt: DateTime.utc(2025, 1, 1, 12, 0),
      );

      expect(order.subtotal, 1500.0);
      expect(order.total, 1560.0);
      expect(order.totalAmount, 1560.0);
      // Orders are created by place_order() in the database, so the app
      // never builds an insert payload; the stored total wins when present.
      final saved = OrderModel.fromJson({
        'id': 'order-uuid-123',
        'total_amount': 1560,
        'order_items': [
          {'product_id': '1', 'unit_price': 500, 'quantity': 3},
        ],
      });
      expect(saved.total, 1560.0);
      expect(saved.items.single.subtotal, 1500.0);
    });
  });
}
