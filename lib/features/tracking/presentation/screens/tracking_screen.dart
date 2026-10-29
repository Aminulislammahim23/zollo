import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/support.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../orders/domain/models/order_model.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../domain/tracking_event_model.dart';
import '../../providers/tracking_provider.dart';
import '../widgets/tracking_timeline.dart';

/// `/tracking/:orderId`, spec C15.
class TrackingScreen extends ConsumerWidget {
  final String orderId;

  const TrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));
    // Shipments are optional: without them the timeline follows the order status.
    final shipments = ref.watch(shipmentsByOrderProvider(orderId)).value ?? const <Shipment>[];

    return Scaffold(
      appBar: AppTopBar(
        title: 'Track order',
        subtitle: 'Order ${formatOrderNumber(orderId)}',
        fallbackRoute: '/order-history',
      ),
      body: orderAsync.when(
        loading: () => const ShimmerList(count: 2, itemHeight: 160),
        error: (error, _) => ErrorView(
          title: "Couldn't load tracking",
          error: error,
          onRetry: () {
            ref.invalidate(orderDetailsProvider(orderId));
            ref.invalidate(shipmentsByOrderProvider(orderId));
          },
        ),
        data: (order) {
          if (order == null) {
            return const EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'Order not found',
              message: "We couldn't find tracking for this order.",
            );
          }
          final shipment = shipments.isEmpty ? null : shipments.first;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(orderDetailsProvider(orderId));
              ref.invalidate(shipmentsByOrderProvider(orderId));
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.m),
              children: [
                _StatusCard(order: order, shipment: shipment),
                const SizedBox(height: AppSpacing.cardGap),
                InfoCard(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: TrackingTimeline(
                    steps: shipment != null && shipment.events.isNotEmpty && order.status != OrderStatus.cancelled
                        ? TimelineStep.fromEvents(shipment.events)
                        : TimelineStep.fromOrder(order),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outline(
                        label: 'Chat with seller',
                        height: 48,
                        onPressed: () => context.push('/messages'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: AppButton.outline(
                        label: 'Get help',
                        height: 48,
                        onPressed: () => contactSupport(
                          context,
                          subject: 'Delivery help for ${formatOrderNumber(order.id)}',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order, required this.shipment});

  final OrderModel order;
  final Shipment? shipment;

  @override
  Widget build(BuildContext context) {
    final eta = shipment?.estimatedDeliveryDate;
    final headline = switch (order.status) {
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Order cancelled',
      _ => eta != null ? 'Arriving by ${formatDate(eta)}' : 'Preparing your order',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: order.status == OrderStatus.cancelled ? AppColors.error : AppColors.primary,
        borderRadius: AppRadius.bannerAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StatusText.labelOf(order.status).toUpperCase(),
            style: AppText.custom(12, FontWeight.w700, color: AppColors.onPrimaryMuted, letterSpacing: 0.6),
          ),
          const SizedBox(height: 6),
          Text(headline, style: AppText.custom(22, FontWeight.w800, color: AppColors.white)),
          if (shipment != null) ...[
            const SizedBox(height: 6),
            Text(
              [
                if (shipment!.courierName != null && shipment!.courierName!.isNotEmpty) 'With ${shipment!.courierName}',
                if (shipment!.trackingNumber.isNotEmpty) 'Tracking ${shipment!.trackingNumber}',
              ].join(' · '),
              style: AppText.custom(13, FontWeight.w500, color: AppColors.onPrimaryMuted),
            ),
          ],
        ],
      ),
    );
  }
}
