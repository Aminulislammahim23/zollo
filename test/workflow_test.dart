import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zollo/features/products/data/repositories/product_repository.dart';
import 'package:zollo/features/products/domain/models/product.dart';
import 'package:zollo/features/products/presentation/providers/products_provider.dart';
import 'package:zollo/features/orders/data/repositories/order_repository.dart';
import 'package:zollo/features/orders/domain/models/order_model.dart';
import 'package:zollo/features/orders/presentation/providers/order_provider.dart';

class FakeProductRepository implements ProductRepository {
  final List<Product> products;
  const FakeProductRepository(this.products);

  @override
  Future<List<Product>> getProducts() async => products;
}

class FakeOrderRepository implements OrderRepository {
  final List<OrderModel> orders;
  FakeOrderRepository(this.orders);

  @override
  Future<void> saveOrder(OrderModel order) async {
    orders.insert(0, order);
  }

  @override
  Future<OrderModel?> getOrderById(String id) async {
    try {
      return orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<OrderModel>> getOrders() async {
    return orders;
  }
}

void main() {
  group('Day 5-6: Product Repository & Provider Tests', () {
    test('productsProvider loads successfully with fake repo', () async {
      const sampleProduct = Product(
        id: 'p001',
        title: 'Wireless Headphones',
        description: 'Comfortable wireless headphones',
        imageUrl: '',
        price: 2499.0,
        rating: 4.5,
        category: 'Electronics',
        stock: 15,
      );

      const fakeProdRepo = FakeProductRepository([sampleProduct]);

      final container = ProviderContainer(
        overrides: [productRepositoryProvider.overrideWithValue(fakeProdRepo)],
      );
      addTearDown(container.dispose);

      final products = await container.read(productsProvider.future);
      expect(products.length, 1);
      expect(products[0].title, 'Wireless Headphones');
    });
  });

  group('Day 9-10: Order Repository & Providers Tests', () {
    test(
      'myOrdersProvider and orderDetailsProvider load correctly with fake repo',
      () async {
        final sampleOrder = OrderModel(
          id: 'ord-999',
          userId: 'usr-123',
          items: [
            const OrderItem(
              productId: 'p001',
              productName: 'Wireless Headphones',
              price: 2499.0,
              quantity: 1,
            ),
          ],
          shippingAddress: 'Chittagong, Bangladesh',
          shippingFee: 60.0,
          status: OrderStatus.confirmed,
          createdAt: DateTime.utc(2025, 2, 1, 10, 0),
        );

        final fakeRepo = FakeOrderRepository([sampleOrder]);

        final container = ProviderContainer(
          overrides: [orderRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        // Test order history / myOrdersProvider
        final orders = await container.read(myOrdersProvider.future);
        expect(orders.length, 1);
        expect(orders.first.id, 'ord-999');
        expect(orders.first.status, OrderStatus.confirmed);

        // Test order details / orderByIdProvider (orderDetailsProvider)
        final fetchedOrder = await container.read(
          orderDetailsProvider('ord-999').future,
        );
        expect(fetchedOrder, isNotNull);
        expect(fetchedOrder?.shippingAddress, 'Chittagong, Bangladesh');
        expect(fetchedOrder?.items.first.productName, 'Wireless Headphones');
        expect(fetchedOrder?.total, 2559.0);
      },
    );

    test('placeOrderProvider saves order and invalidates history', () async {
      final fakeRepo = FakeOrderRepository([]);

      final container = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final newOrder = OrderModel(
        id: 'ord-888',
        userId: 'usr-123',
        items: [
          const OrderItem(
            productId: 'p002',
            productName: 'Smart Watch',
            price: 3499.0,
            quantity: 2,
          ),
        ],
        shippingAddress: 'Sylhet, Bangladesh',
        shippingFee: 60.0,
        status: OrderStatus.pending,
        createdAt: DateTime.utc(2025, 2, 2, 14, 0),
      );

      final placed = await container
          .read(placeOrderProvider.notifier)
          .placeOrder(newOrder);
      expect(placed.id, 'ord-888');

      final orders = await container.read(myOrdersProvider.future);
      expect(orders.length, 1);
      expect(orders.first.id, 'ord-888');
    });
  });
}
