import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  static const _items = [
    (icon: Icons.home_outlined, label: 'Home'),
    (icon: Icons.grid_view_outlined, label: 'Categories'),
    (icon: Icons.shopping_cart_outlined, label: 'Cart'),
    (icon: Icons.person_outline, label: 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _items[i].icon,
                    label: _items[i].label,
                    selected: i == currentIndex,
                    badge: i == 2 ? cartCount : 0,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '$label, $badge items' : label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        highlightShape: BoxShape.rectangle,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CartBadge(
              count: badge,
              child: Icon(icon, size: AppSpacing.iconBar, color: color),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              style: AppText.custom(
                11,
                selected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small primary count bubble on the top-right of [child].
class CartBadge extends StatelessWidget {
  const CartBadge({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -5,
          right: -9,
          child: Container(
            constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.chipAll,
              border: Border.all(color: AppColors.surface, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              count > 99 ? '99+' : '$count',
              style: AppText.custom(10, FontWeight.w800, color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }
}
