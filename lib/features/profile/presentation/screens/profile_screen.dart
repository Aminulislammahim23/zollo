import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/support.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';

/// Bottom-nav tab 4, spec C17.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final wishlistCount = ref.watch(wishlistProvider).value?.length ?? 0;

    void comingSoon(String feature) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$feature is coming soon.')),
        );

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.l,
              MediaQuery.paddingOf(context).top + AppSpacing.xl,
              AppSpacing.l,
              20,
            ),
            child: user == null
                ? Row(
                    children: [
                      const _Avatar(initial: null),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome to zollo', style: AppText.title.withColor(AppColors.white)),
                            Text(
                              'Log in or sign up',
                              style: AppText.custom(13, FontWeight.w500, color: AppColors.onPrimaryMuted),
                            ),
                          ],
                        ),
                      ),
                      AppButton.deal(
                        label: 'Log in',
                        size: AppButtonSize.small,
                        fullWidth: false,
                        onPressed: () => context.push('/login'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _Avatar(initial: user.initial),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.title.withColor(AppColors.white),
                            ),
                            Text(
                              user.phoneNumber != null
                                  ? PhoneField.display(user.phoneNumber!)
                                  : (user.email ?? ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.custom(13, FontWeight.w500, color: AppColors.onPrimaryMuted),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: AppColors.primaryOnDark,
                        shape: const StadiumBorder(),
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: () => context.push('/edit-profile'),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 36, minWidth: 48),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                            alignment: Alignment.center,
                            child: Text(
                              'Edit',
                              semanticsLabel: 'Edit profile',
                              style: AppText.custom(13, FontWeight.w700, color: AppColors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('My orders', style: AppText.custom(15, FontWeight.w800))),
                          TextButton(
                            onPressed: () => context.push('/order-history'),
                            child: const Text('View all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _OrderShortcut(icon: Icons.credit_card_outlined, label: 'To pay', tab: 'processing'),
                          _OrderShortcut(icon: Icons.inventory_2_outlined, label: 'Processing', tab: 'processing'),
                          _OrderShortcut(icon: Icons.local_shipping_outlined, label: 'Shipped', tab: 'shipped'),
                          _OrderShortcut(icon: Icons.star_outline_rounded, label: 'To review', tab: 'delivered'),
                          _OrderShortcut(icon: Icons.assignment_return_outlined, label: 'Returns', tab: 'delivered'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.cardGap),
                InfoCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _MenuRow(
                        icon: Icons.favorite_border,
                        label: 'Wishlist',
                        hint: '$wishlistCount ${wishlistCount == 1 ? 'item' : 'items'}',
                        onTap: () => context.push('/wishlist'),
                      ),
                      _MenuRow(
                        icon: Icons.confirmation_number_outlined,
                        label: 'My vouchers',
                        onTap: () => context.push('/vouchers'),
                      ),
                      _MenuRow(
                        icon: Icons.location_on_outlined,
                        label: 'Address book',
                        onTap: () => context.push('/addresses'),
                      ),
                      _MenuRow(
                        icon: Icons.chat_bubble_outline,
                        label: 'Messages',
                        onTap: () => context.push('/messages'),
                      ),
                      _MenuRow(
                        icon: Icons.notifications_none,
                        label: 'Notifications',
                        onTap: () => context.push('/notifications'),
                      ),
                      _MenuRow(
                        icon: Icons.help_outline,
                        label: 'Help center',
                        onTap: () => contactSupport(context, subject: 'Help request'),
                      ),
                      _MenuRow(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () => context.push('/settings'),
                      ),
                      _MenuRow(
                        icon: Icons.storefront_outlined,
                        label: 'Sell on zollo',
                        onTap: () => comingSoon('Selling on zollo'),
                        last: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial});

  final String? initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: initial == null
          ? const Icon(Icons.person_outline, size: 28, color: AppColors.primary)
          : Text(initial!, style: AppText.custom(22, FontWeight.w800, color: AppColors.primary)),
    );
  }
}

class _OrderShortcut extends StatelessWidget {
  const _OrderShortcut({required this.icon, required this.label, required this.tab});

  final IconData icon;
  final String label;
  final String tab;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: AppRadius.tileAll,
          onTap: () => context.push('/order-history?tab=$tab'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24, color: AppColors.primary),
                  const SizedBox(height: 6),
                  Text(label, textAlign: TextAlign.center, style: AppText.micro),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.hint,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: AppColors.surfaceAlt)),
        ),
        child: Row(
          children: [
            Icon(icon, size: AppSpacing.iconInline, color: AppColors.inkSoft),
            const SizedBox(width: AppSpacing.m),
            Expanded(child: Text(label, style: AppText.custom(14, FontWeight.w600))),
            if (hint != null) ...[
              Text(hint!, style: AppText.caption.withColor(AppColors.muted)),
              const SizedBox(width: AppSpacing.xs),
            ],
            const Icon(Icons.chevron_right, size: 16, color: AppColors.hint),
          ],
        ),
      ),
    );
  }
}
