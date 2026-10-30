import '../../domain/models/order_model.dart';
import '../../domain/models/place_order_request.dart';

abstract interface class OrderRepository {
  /// Places the order and returns it as saved. Throws an `OrderException`
  /// for the error codes raised by `place_order()`.
  Future<OrderModel> saveOrder(PlaceOrderRequest request);

  Future<OrderModel?> getOrderById(String id);

  Future<List<OrderModel>> getOrders();

  /// Cancels a pending order (`cancel_order()`); the database releases the
  /// reserved stock. Throws `OrderException` (ORDER_NOT_CANCELLABLE, ...).
  Future<OrderModel> cancelOrder(String orderId, {String? reason});
}
