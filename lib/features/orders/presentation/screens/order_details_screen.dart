import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/order_providers.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: TextButton(
            onPressed: () {
              ref.invalidate(orderDetailsProvider(orderId));
            },
            child: const Text('Failed to load. Tap to retry'),
          ),
        ),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Order #${order.id}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Placed: ${order.createdAt.toLocal()}'),
              const SizedBox(height: 8),
              Chip(label: Text(order.status.name.toUpperCase())),
              const Divider(height: 32),
              const Text(
                'Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...order.items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.productName),
                  subtitle: Text('Quantity: ${item.quantity}'),
                  trailing: Text(
                    '৳${item.subtotal.toStringAsFixed(2)}',
                  ),
                ),
              ),
              const Divider(height: 32),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Order Total'),
                trailing: Text(
                  '৳${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
