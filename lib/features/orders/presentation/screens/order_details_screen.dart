import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/support.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/order_model.dart';
import '../../../tracking/providers/tracking_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_thumbnail.dart';

/// `/order-details/:orderId`, spec C14.
class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  static String headlineFor(OrderStatus status) => switch (status) {
    OrderStatus.pending => 'Order received',
    OrderStatus.confirmed => 'Order confirmed',
    OrderStatus.processing => 'Packing your order',
    OrderStatus.shipped => 'On the way',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Order cancelled',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Order details',
        fallbackRoute: '/order-history',
      ),
      body: orderAsync.when(
        loading: () => const ShimmerList(count: 3, itemHeight: 120),
        error: (error, _) => ErrorView(
          title: "Couldn't load this order",
          error: error,
          onRetry: () => ref.invalidate(orderDetailsProvider(orderId)),
        ),
        data: (order) {
          if (order == null) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Order not found',
              message:
                  'It may have been removed or belongs to another account.',
              actionLabel: 'My orders',
              onAction: () => context.go('/order-history'),
            );
          }
          return _OrderDetailsBody(order: order);
        },
      ),
    );
  }
}

class _OrderDetailsBody extends ConsumerWidget {
  const _OrderDetailsBody({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasShipment =
        ref.watch(shipmentsByOrderProvider(order.id)).value?.isNotEmpty ??
        false;
    final canTrack =
        order.status != OrderStatus.cancelled &&
        (hasShipment || order.status == OrderStatus.shipped);

    Widget cardTitle(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Text(text, style: AppText.cardTitle),
    );

    Widget row(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.meta
                  .withWeight(bold ? FontWeight.w800 : FontWeight.w500)
                  .withColor(bold ? AppColors.ink : AppColors.muted),
            ),
          ),
          Text(
            value,
            style: (bold ? AppText.cardTitle : AppText.label)
                .withWeight(bold ? FontWeight.w800 : FontWeight.w700)
                .withColor(bold ? AppColors.primary : AppColors.ink),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.m),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: order.status == OrderStatus.cancelled
                ? AppColors.error
                : AppColors.primary,
            borderRadius: AppRadius.bannerAll,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                StatusText.labelOf(order.status).toUpperCase(),
                style: AppText.captionStrong.copyWith(
                  color: AppColors.onPrimaryMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                OrderDetailsScreen.headlineFor(order.status),
                style: AppText.bannerTitle.withColor(AppColors.white),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Placed ${formatDate(order.createdAt)} · ${formatOrderNumber(order.id)}',
                style: AppText.meta.withColor(AppColors.onPrimaryMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cardTitle('Items'),
              for (var i = 0; i < order.items.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                    child: Divider(),
                  ),
                Row(
                  children: [
                    OrderThumbnail(
                      productId: order.items[i].productId,
                      imageUrl: order.items[i].imageUrl,
                      size: 56,
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.items[i].productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Qty ${order.items[i].quantity}',
                            style: AppText.caption.withColor(AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      formatTaka(order.items[i].subtotal),
                      style: AppText.rowTitle,
                    ),
                  ],
                ),
              ],
              if (order.items.isEmpty)
                Text(
                  'Item details are unavailable.',
                  style: AppText.caption.withColor(AppColors.muted),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cardTitle('Delivery'),
              if (order.recipient.isNotEmpty)
                Text(order.recipient, style: AppText.bodyStrong),
              const SizedBox(height: AppSpacing.xs),
              Text(
                order.deliveryAddress,
                style: AppText.meta.copyWith(
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        InfoCard(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: cardTitle('Payment'),
              ),
              row('Items total', formatTaka(order.subtotal)),
              row('Delivery', formatTaka(order.shippingFee)),
              row('Payment method', order.paymentMethod.label),
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.s),
                child: Divider(),
              ),
              row('Total', formatTaka(order.total), bold: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        if (canTrack) ...[
          AppButton.primary(
            label: 'Track order',
            icon: Icons.local_shipping_outlined,
            onPressed: () => context.push('/tracking/${order.id}'),
          ),
          const SizedBox(height: AppSpacing.m),
        ],
        if (order.status == OrderStatus.delivered) ...[
          AppButton.outline(
            label: 'Request a return',
            icon: Icons.assignment_return_outlined,
            onPressed: () => context.push('/return-request', extra: order),
          ),
          const SizedBox(height: AppSpacing.m),
        ],
        Center(
          child: TextButton(
            onPressed: () => contactSupport(
              context,
              subject: 'Help with order ${formatOrderNumber(order.id)}',
            ),
            child: const Text('Need help?'),
          ),
        ),
      ],
    );
  }
}
