import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../domain/models/cart_item.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    this.selecting = false,
    this.selected = false,
    this.onSelectedChanged,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  /// Edit (delete) mode: a checkbox replaces the remove button.
  final bool selecting;
  final bool selected;
  final ValueChanged<bool>? onSelectedChanged;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selecting)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Checkbox(
              value: selected,
              onChanged: (v) => onSelectedChanged?.call(v ?? false),
              semanticLabel: 'Select ${product.title}',
            ),
          ),
        InkWell(
          onTap: () => context.push('/product-details', extra: product),
          borderRadius: AppRadius.tileAll,
          child: AppNetworkImage(
            url: product.imageUrl,
            width: 80,
            height: 80,
            borderRadius: AppRadius.tileAll,
            semanticLabel: product.title,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodySmall,
                        ),
                        if (item.variant != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.variant!,
                            style: AppText.caption.withColor(AppColors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!selecting)
                    SizedBox.square(
                      dimension: 40,
                      child: IconButton(
                        tooltip: 'Remove ${product.title}',
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        onPressed: onRemove,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: AppSpacing.iconInline,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: AppSpacing.xs,
                spacing: AppSpacing.s,
                children: [
                  Text(formatTaka(product.price), style: AppText.price),
                  QuantityStepper(
                    value: item.quantity,
                    max: product.stock,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
