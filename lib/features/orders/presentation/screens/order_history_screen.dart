import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../../reviews/providers/review_providers.dart';
import '../../domain/models/order_model.dart';
import '../providers/order_provider.dart';
import '../widgets/order_thumbnail.dart';

enum OrderTab {
  all('All'),
  processing('Processing'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderTab(this.label);
  final String label;

  bool matches(OrderModel order) => switch (this) {
    OrderTab.all => true,
    OrderTab.processing => order.isActive,
    OrderTab.shipped => order.status == OrderStatus.shipped,
    OrderTab.delivered => order.status == OrderStatus.delivered,
    OrderTab.cancelled => order.status == OrderStatus.cancelled,
  };

  static OrderTab fromQuery(String? value) => OrderTab.values.firstWhere(
    (t) => t.name == value,
    orElse: () => OrderTab.all,
  );
}

/// `/order-history?tab=<all|processing|shipped|delivered|cancelled>`, spec C13.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key, this.initialTab = OrderTab.all});

  final OrderTab initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return DefaultTabController(
      length: OrderTab.values.length,
      initialIndex: initialTab.index,
      child: Scaffold(
        appBar: AppTopBar(
          title: 'My orders',
          fallbackRoute: '/account',
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: SizedBox(
              height: 44,
              child: TabBar(
                isScrollable: true,
                indicatorWeight: 3,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                tabs: [for (final t in OrderTab.values) Tab(text: t.label)],
              ),
            ),
          ),
        ),
        body: ordersAsync.when(
          loading: () => const ShimmerList(itemHeight: 150),
          error: (error, _) => ErrorView(
            title: "Couldn't load your orders",
            error: error,
            onRetry: () => ref.invalidate(myOrdersProvider),
          ),
          data: (orders) => TabBarView(
            children: [
              for (final tab in OrderTab.values)
                _OrderList(orders: orders.where(tab.matches).toList()),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderList extends ConsumerWidget {
  const _OrderList({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders here yet.',
        message: 'Orders you place will show up here.',
        actionLabel: 'Start shopping',
        onAction: () => context.go('/home'),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(myOrdersProvider);
        await ref
            .read(myOrdersProvider.future)
            .catchError((_) => <OrderModel>[]);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.m),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.cardGap),
        itemBuilder: (context, i) => OrderCard(order: orders[i]),
      ),
    );
  }
}

class OrderCard extends ConsumerWidget {
  const OrderCard({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final first = order.items.isNotEmpty ? order.items.first : null;
    final more = order.items.length - 1;
    final firstProduct = first == null
        ? null
        : ref.watch(productLookupProvider)[first.productId];
    final canReview = order.status == OrderStatus.delivered && first != null
        ? ref.watch(canUserReviewProvider(first.productId)).value ?? false
        : false;

    void openDetails() => context.push('/order-details/${order.id}');

    final (String label, VoidCallback action) = switch (order.status) {
      OrderStatus.shipped => (
        'Track',
        () => context.push('/tracking/${order.id}'),
      ),
      OrderStatus.delivered when canReview && firstProduct != null => (
        'Write review',
        () => context.push('/write-review', extra: firstProduct),
      ),
      _ => ('Details', openDetails),
    };

    return InfoCard(
      onTap: openDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(formatOrderNumber(order.id), style: AppText.label),
              ),
              StatusText(order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              if (first != null) OrderThumbnail(productId: first.productId),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      first == null
                          ? 'Order'
                          : more > 0
                          ? '${first.productName} + $more more'
                          : first.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'} · placed ${formatDate(order.createdAt)}',
                      style: AppText.meta.withColor(AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10, bottom: AppSpacing.s),
            child: Divider(),
          ),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppText.meta.withColor(AppColors.muted),
                    children: [
                      const TextSpan(text: 'Total '),
                      TextSpan(
                        text: formatTaka(order.total),
                        style: AppText.labelHeavy,
                      ),
                    ],
                  ),
                ),
              ),
              AppButton.outline(
                label: label,
                size: AppButtonSize.small,
                fullWidth: false,
                onPressed: action,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
