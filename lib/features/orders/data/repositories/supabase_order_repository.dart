import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/order_model.dart';
import 'order_repository.dart';

class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> saveOrder(OrderModel order) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('Please sign in before placing an order.');
    }

    if (user.id != order.userId) {
      throw StateError('Order user does not match signed-in user.');
    }

    if (order.items.isEmpty) {
      throw ArgumentError('Cannot place an empty order.');
    }

    if (order.items.any(
          (item) => item.quantity <= 0 || item.price < 0,
    )) {
      throw ArgumentError('Invalid order item.');
    }

    if (order.shippingFee < 0 ||
        order.shippingAddress.trim().isEmpty) {
      throw ArgumentError('Invalid shipping details.');
    }

    await _client
        .from('orders')
        .insert(order.toInsertJson());
  }

  @override
  Future<OrderModel?> getOrderById(String id) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('Please sign in to view this order.');
    }

    final row = await _client
        .from('orders')
        .select()
        .eq('id', id)
        .eq('user_id', user.id)
        .maybeSingle();

    if (row == null) return null;

    return OrderModel.fromJson(row);
  }

  @override
  Future<List<OrderModel>> getOrders() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('Please sign in to view your orders.');
    }

    final rows = await _client
        .from('orders')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return rows
        .map((row) => OrderModel.fromJson(row))
        .toList();
  }
}
