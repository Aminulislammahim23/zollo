import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

enum DiscountBadgeVariant { discount, priceDrop, outOfStock }

class DiscountBadge extends StatelessWidget {
  const DiscountBadge({
    super.key,
    required String this.label,
    this.variant = DiscountBadgeVariant.discount,
  }) : percent = null;

  /// `-23%`.
  const DiscountBadge.percent(int this.percent, {super.key})
      : label = null,
        variant = DiscountBadgeVariant.discount;

  const DiscountBadge.priceDrop({super.key, String this.label = 'Price drop'})
      : percent = null,
        variant = DiscountBadgeVariant.priceDrop;

  const DiscountBadge.outOfStock({super.key, String this.label = 'Out of stock'})
      : percent = null,
        variant = DiscountBadgeVariant.outOfStock;

  final String? label;
  final int? percent;
  final DiscountBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final isError = variant == DiscountBadgeVariant.outOfStock;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorBg : AppColors.discountBg,
        borderRadius: AppRadius.badgeAll,
      ),
      child: Text(
        label ?? '-$percent%',
        style: AppText.custom(
          11,
          FontWeight.w800,
          color: isError ? AppColors.error : AppColors.discountText,
        ),
      ),
    );
  }
}
