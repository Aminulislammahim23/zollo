import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/supabase_order_repository.dart';
import '../../domain/models/order_model.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return SupabaseOrderRepository(Supabase.instance.client);
});

final orderHistoryProvider =
    FutureProvider<List<OrderModel>>((ref) async {
  ref.watch(currentUserProvider.select((u) => u?.id));
  return ref.watch(orderRepositoryProvider).getOrders();
});

final myOrdersProvider = orderHistoryProvider;

final orderByIdProvider =
    FutureProvider.family<OrderModel?, String>((ref, id) async {
  return ref.watch(orderRepositoryProvider).getOrderById(id);
});

final orderDetailsProvider =
    FutureProvider.family<OrderModel?, String>((ref, id) async {
  return ref.watch(orderRepositoryProvider).getOrderById(id);
});

final placeOrderProvider =
    AsyncNotifierProvider<PlaceOrderController, OrderModel?>(
  PlaceOrderController.new,
);

class PlaceOrderController extends AsyncNotifier<OrderModel?> {
  @override
  OrderModel? build() => null;

  Future<OrderModel> placeOrder(OrderModel order) async {
    if (state.isLoading) {
      throw StateError('An order submission is already in progress.');
    }

    state = const AsyncLoading();

    try {
      await ref.read(orderRepositoryProvider).saveOrder(order);

      state = AsyncData(order);
      ref.invalidate(orderHistoryProvider);
      ref.invalidate(myOrdersProvider);

      return order;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
