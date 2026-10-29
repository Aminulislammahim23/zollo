import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/app_notification.dart';
import '../providers/notification_providers.dart';

/// `/notifications`, spec C25.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const _tabs = ['All', 'Orders', 'Promotions'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppTopBar(
          title: 'Notifications',
          actions: [
            TextButton(
              onPressed: unread == 0 ? null : () => ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: SizedBox(
              height: 44,
              child: TabBar(
                isScrollable: true,
                indicatorWeight: 3,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                tabs: [for (final t in _tabs) Tab(text: t)],
              ),
            ),
          ),
        ),
        body: async.when(
          loading: () => const ShimmerList(itemHeight: 72),
          error: (error, _) => ErrorView(
            title: "Couldn't load notifications",
            error: error,
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
          data: (items) => TabBarView(
            children: [
              _NotificationList(items: items),
              _NotificationList(items: items.where((n) => n.type == NotificationType.order).toList()),
              _NotificationList(items: items.where((n) => n.type == NotificationType.promotion).toList()),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.items});

  final List<AppNotification> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none,
        title: "You're all caught up",
        message: 'New updates about orders and offers will appear here.',
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final n = items[i];
        final isOrder = n.type == NotificationType.order;
        return InkWell(
          onTap: () {
            ref.read(notificationsProvider.notifier).markRead(n.id);
            if (n.deepLink != null) context.push(n.deepLink!);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: 14),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.surfaceAlt))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isOrder ? AppColors.primaryTint : AppColors.discountBg,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Text(
                    n.tag,
                    style: AppText.custom(11, FontWeight.w800,
                        color: isOrder ? AppColors.primary : AppColors.discountText),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Semantics(
                    label: n.read ? null : 'Unread',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: AppText.custom(14, FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(n.body, style: AppText.custom(13, FontWeight.w500, color: AppColors.muted, height: 1.4)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(formatRelative(n.createdAt), style: AppText.custom(11, FontWeight.w500, color: AppColors.hint)),
                      ],
                    ),
                  ),
                ),
                if (!n.read)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: AppSpacing.s, top: 6),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
