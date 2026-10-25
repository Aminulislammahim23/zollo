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

    final fullPayload = order.toInsertJson();

    try {
      // 1. Try inserting into orders with items column
      await _client.from('orders').insert(fullPayload);
    } on PostgrestException catch (e) {
      // 2. If 'items' column does not exist in 'orders' table
      if (e.message.contains('items') ||
          e.message.contains('schema cache') ||
          e.code == 'PGRST204') {
        final orderOnlyPayload = Map<String, dynamic>.from(fullPayload)
          ..remove('items');

        try {
          await _client.from('orders').insert(orderOnlyPayload);
        } on PostgrestException catch (e2) {
          if (e2.message.contains('total_amount')) {
            orderOnlyPayload.remove('total_amount');
            await _client.from('orders').insert(orderOnlyPayload);
          } else {
            throw Exception(e2.message);
          }
        }

        // Try inserting into order_items table
        try {
          final orderItemsData = order.items
              .map((item) => {
                    'order_id': order.id,
                    'product_id': item.productId,
                    'product_name': item.productName,
                    'price': item.price,
                    'quantity': item.quantity,
                  })
              .toList();

          await _client.from('order_items').insert(orderItemsData);
        } on PostgrestException catch (_) {
          // If order_items table doesn't exist, order header was already inserted
        }
      } else if (e.message.contains('total_amount')) {
        final payload = Map<String, dynamic>.from(fullPayload)
          ..remove('total_amount');
        await _client.from('orders').insert(payload);
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      rethrow;
    }
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

    List<OrderItem>? orderItems;
    if (row['items'] == null) {
      try {
        final itemRows = await _client
            .from('order_items')
            .select()
            .eq('order_id', row['id']);

        orderItems = itemRows.map((itemRow) {
          return OrderItem(
            productId: itemRow['product_id'] as String? ?? '',
            productName: itemRow['product_name'] as String? ?? '',
            price: ((itemRow['price'] ?? 0) as num).toDouble(),
            quantity: ((itemRow['quantity'] ?? 1) as num).toInt(),
          );
        }).toList();
      } catch (_) {}
    }

    return OrderModel.fromJson(row, fallbackItems: orderItems);
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

    final orders = <OrderModel>[];

    for (final row in rows) {
      List<OrderItem>? orderItems;
      if (row['items'] == null) {
        try {
          final itemRows = await _client
              .from('order_items')
              .select()
              .eq('order_id', row['id']);

          orderItems = itemRows.map((itemRow) {
            return OrderItem(
              productId: itemRow['product_id'] as String? ?? '',
              productName: itemRow['product_name'] as String? ?? '',
              price: ((itemRow['price'] ?? 0) as num).toDouble(),
              quantity: ((itemRow['quantity'] ?? 1) as num).toInt(),
            );
          }).toList();
        } catch (_) {}
      }

      orders.add(OrderModel.fromJson(row, fallbackItems: orderItems));
    }

    return orders;
  }
}
