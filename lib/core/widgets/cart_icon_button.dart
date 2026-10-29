import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/presentation/providers/cart_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_bottom_nav.dart';

/// Cart icon with a count badge; opens the Cart tab.
class CartIconButton extends ConsumerWidget {
  const CartIconButton({super.key, this.circle = false});

  /// White 44 circle (for use over photos).
  final bool circle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartItemCountProvider);
    final icon = CartBadge(
      count: count,
      child: const Icon(
        Icons.shopping_cart_outlined,
        size: AppSpacing.iconBar,
        color: AppColors.ink,
      ),
    );
    return IconButton(
      tooltip: count > 0 ? 'Cart, $count items' : 'Cart',
      onPressed: () => context.go('/cart'),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(AppSpacing.tapTarget),
      ),
      icon: circle
          ? Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: icon,
            )
          : icon,
    );
  }
}
