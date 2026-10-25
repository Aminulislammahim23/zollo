import '../../domain/models/order_model.dart';

abstract interface class OrderRepository {
  Future<void> saveOrder(OrderModel order);

  Future<OrderModel?> getOrderById(String id);

  Future<List<OrderModel>> getOrders();
}
