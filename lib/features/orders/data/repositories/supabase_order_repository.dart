import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/order_model.dart';
import '../../domain/models/place_order_request.dart';
import '../../domain/order_exception.dart';
import 'order_repository.dart';

class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository(this._client);

  final SupabaseClient _client;

  static const _withItems = '*, order_items(*)';

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const OrderException(OrderErrorCode.notAuthenticated);
    }
    return user.id;
  }

  /// Runs [call] and turns the database's order error codes into
  /// [OrderException]s; anything else is rethrown unchanged.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PostgrestException catch (e) {
      final code = OrderErrorCode.fromCode(e.message);
      if (code == null) rethrow;
      throw OrderException(code, detail: e.details?.toString());
    }
  }

  @override
  Future<OrderModel> saveOrder(PlaceOrderRequest request) {
    // NOT_AUTHENTICATED is raised by place_order() itself.
    return _guard(() async {
      // Prices, stock and the delivery fee are taken from the database.
      final result = await _client.rpc(
        'place_order',
        params: request.toRpcParams(),
      );
      final row = Map<String, dynamic>.from(
        (result is List ? result.first : result) as Map,
      );
      // place_order() returns the orders row; fetch it again with its lines.
      return await getOrderById(row['id'] as String) ??
          OrderModel.fromJson(row);
    });
  }

  @override
  Future<OrderModel?> getOrderById(String id) async {
    final row = await _client
        .from('orders')
        .select(_withItems)
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    return row == null ? null : OrderModel.fromJson(row);
  }

  @override
  Future<List<OrderModel>> getOrders() async {
    final rows = await _client
        .from('orders')
        .select(_withItems)
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return rows.map(OrderModel.fromJson).toList();
  }

  @override
  Future<OrderModel> cancelOrder(String orderId, {String? reason}) {
    return _guard(() async {
      await _client.rpc(
        'cancel_order',
        params: {'p_order_id': orderId, 'p_reason': reason},
      );
      final order = await getOrderById(orderId);
      if (order == null) {
        throw const OrderException(OrderErrorCode.orderNotFound);
      }
      return order;
    });
  }
}
