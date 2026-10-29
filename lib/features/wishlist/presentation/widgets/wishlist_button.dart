import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';

/// Heart toggle. [compact] draws a white 32 circle (for photo overlays) inside
/// the 48dp hit area; otherwise it is a plain icon button.
class WishlistButton extends ConsumerWidget {
  const WishlistButton({
    super.key,
    required this.productId,
    this.compact = false,
    this.circle = false,
  });

  final String productId;
  final bool compact;

  /// White 44 circle, used over the product-details photo.
  final bool circle;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    if (ref.read(currentUserProvider) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Log in to save products to your wishlist.'),
          action: SnackBarAction(
            label: 'Log in',
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }
    try {
      await ref.read(wishlistProvider.notifier).toggle(productId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Couldn't update your wishlist. ${ErrorView.describe(error)}",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final isFavorite = wishlist.value?.contains(productId) ?? false;

    final icon = Icon(
      isFavorite ? Icons.favorite : Icons.favorite_border,
      color: isFavorite ? AppColors.primary : AppColors.ink,
      size: compact ? AppSpacing.iconSmall : AppSpacing.iconBar,
    );

    final visualSize = compact ? 32.0 : (circle ? 44.0 : 0.0);

    return IconButton(
      tooltip: isFavorite ? 'Remove from wishlist' : 'Add to wishlist',
      onPressed: wishlist.isLoading ? null : () => _toggle(context, ref),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(AppSpacing.tapTarget),
      ),
      icon: visualSize == 0
          ? icon
          : Container(
              width: visualSize,
              height: visualSize,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: icon,
            ),
    );
  }
}
