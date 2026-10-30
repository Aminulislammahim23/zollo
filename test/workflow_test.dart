import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zollo/features/products/data/repositories/product_repository.dart';
import 'package:zollo/features/products/domain/models/product.dart';
import 'package:zollo/features/products/presentation/providers/products_provider.dart';
import 'package:zollo/features/orders/data/repositories/order_repository.dart';
import 'package:zollo/features/orders/domain/models/order_model.dart';
import 'package:zollo/features/orders/domain/models/payment_method.dart';
import 'package:zollo/features/orders/domain/models/place_order_request.dart';
import 'package:zollo/features/orders/domain/order_exception.dart';
import 'package:zollo/features/orders/presentation/providers/order_provider.dart';

class FakeProductRepository implements ProductRepository {
  final List<Product> products;
  const FakeProductRepository(this.products);

  @override
  Future<List<Product>> getProducts() async => products;
}

class FakeOrderRepository implements OrderRepository {
  final List<OrderModel> orders;
  FakeOrderRepository(this.orders, {this.failWith});

  /// When set, saveOrder throws this instead of saving.
  OrderException? failWith;

  /// Every request received, including retries.
  final List<PlaceOrderRequest> requests = [];

  @override
  Future<OrderModel> saveOrder(PlaceOrderRequest request) async {
    requests.add(request);
    if (failWith != null) throw failWith!;
    // Same idempotency key -> same order, like place_order().
    final existing = _byKey[request.idempotencyKey];
    if (existing != null) return existing;
    final order = OrderModel(
      id: 'ord-${orders.length + 1}',
      userId: 'user-1',
      items: [
        for (final line in request.items)
          OrderItem(
            productId: line.productId,
            productName: line.productName,
            price: line.unitPrice,
            quantity: line.quantity,
          ),
      ],
      shippingAddress: 'House 12, Road 4, Dhanmondi, Dhaka',
      shippingName: 'Rahim Uddin',
      shippingPhone: '01712345678',
      shippingFee: request.shippingFee,
      paymentMethod: request.paymentMethod,
      status: OrderStatus.pending,
      createdAt: DateTime.utc(2026, 10, 30),
    );
    orders.insert(0, order);
    _byKey[request.idempotencyKey] = order;
    return order;
  }

  final Map<String, OrderModel> _byKey = {};

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

  @override
  Future<OrderModel> cancelOrder(String orderId, {String? reason}) async {
    final i = orders.indexWhere((o) => o.id == orderId);
    if (i < 0) throw const OrderException(OrderErrorCode.orderNotFound);
    if (!orders[i].canCancel) {
      throw const OrderException(OrderErrorCode.orderNotCancellable);
    }
    return orders[i] = orders[i].copyWith(status: OrderStatus.cancelled);
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

      const request = PlaceOrderRequest(
        items: [
          PlaceOrderLine(
            productId: 'p002',
            quantity: 2,
            productName: 'Smart Watch',
            unitPrice: 3499,
          ),
        ],
        addressId: 'a1',
        paymentMethod: PaymentMethod.cashOnDelivery,
        idempotencyKey: 'key-1',
        shippingFee: 60,
      );

      final placed = await container
          .read(placeOrderProvider.notifier)
          .placeOrder(request);
      expect(placed.id, 'ord-1');
      expect(placed.total, 3499 * 2 + 60);

      final orders = await container.read(myOrdersProvider.future);
      expect(orders.length, 1);
      expect(orders.first.id, 'ord-1');
    });
  });
}
