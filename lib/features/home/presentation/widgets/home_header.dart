import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../address/presentation/providers/address_provider.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../../core/widgets/app_bottom_nav.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final address = user == null ? null : ref.watch(defaultAddressProvider).value;
    final unread = ref.watch(unreadNotificationCountProvider);

    final String deliverTo;
    final VoidCallback onDeliverTap;
    if (address != null) {
      final place = [address.area, address.district]
          .where((part) => part.trim().isNotEmpty)
          .join(', ');
      deliverTo = 'Deliver to ${place.isEmpty ? address.city : place}';
      onDeliverTap = () => context.push('/addresses');
    } else {
      deliverTo = 'Add a delivery address';
      onDeliverTap = () => context.push(user == null ? '/login' : '/add-address');
    }

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l,
        MediaQuery.paddingOf(context).top + 20,
        AppSpacing.l,
        AppSpacing.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'zollo',
                        style: AppText.custom(22, FontWeight.w800, color: AppColors.white, letterSpacing: -0.5),
                      ),
                    ),
                    Semantics(
                      button: true,
                      child: InkWell(
                        onTap: onDeliverTap,
                        borderRadius: AppRadius.badgeAll,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.onPrimaryMuted),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  deliverTo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.caption.withColor(AppColors.onPrimaryMuted),
                                ),
                              ),
                              const Icon(Icons.expand_more, size: 16, color: AppColors.onPrimaryMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
                onPressed: () => context.push('/notifications'),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryOnDark,
                  minimumSize: const Size.square(44),
                ),
                icon: CartBadge(
                  count: unread,
                  child: const Icon(Icons.notifications_none, color: AppColors.white, size: AppSpacing.iconBar),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SearchField(
            readOnly: true,
            height: 46,
            fillColor: AppColors.surface,
            onTap: () => context.push('/search'),
          ),
        ],
      ),
    );
  }
}
