import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/supabase_order_repository.dart';
import '../../domain/models/order_model.dart';
import '../../domain/models/place_order_request.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return SupabaseOrderRepository(Supabase.instance.client);
});

final orderHistoryProvider = FutureProvider<List<OrderModel>>((ref) async {
  ref.watch(currentUserProvider.select((u) => u?.id));
  return ref.watch(orderRepositoryProvider).getOrders();
});

final myOrdersProvider = orderHistoryProvider;

final orderByIdProvider = FutureProvider.family<OrderModel?, String>((
  ref,
  id,
) async {
  return ref.watch(orderRepositoryProvider).getOrderById(id);
});

final orderDetailsProvider = FutureProvider.family<OrderModel?, String>((
  ref,
  id,
) async {
  return ref.watch(orderRepositoryProvider).getOrderById(id);
});

final placeOrderProvider =
    AsyncNotifierProvider<PlaceOrderController, OrderModel?>(
      PlaceOrderController.new,
    );

class PlaceOrderController extends AsyncNotifier<OrderModel?> {
  @override
  OrderModel? build() => null;

  Future<OrderModel> placeOrder(PlaceOrderRequest request) async {
    if (state.isLoading) {
      throw StateError('An order submission is already in progress.');
    }

    state = const AsyncLoading();

    try {
      final order = await ref.read(orderRepositoryProvider).saveOrder(request);

      state = AsyncData(order);
      ref.invalidate(orderHistoryProvider);

      return order;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

/// Cancels a pending order and refreshes every view of it.
Future<OrderModel> cancelOrder(WidgetRef ref, String orderId) async {
  final order = await ref
      .read(orderRepositoryProvider)
      .cancelOrder(orderId, reason: 'cancelled_by_customer');
  ref.invalidate(orderHistoryProvider);
  ref.invalidate(orderDetailsProvider(orderId));
  ref.invalidate(orderByIdProvider(orderId));
  return order;
}
