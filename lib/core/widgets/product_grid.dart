import 'package:flutter/material.dart';

import '../../features/products/domain/models/product.dart';
import '../theme/app_spacing.dart';
import 'product_card.dart';

/// Two-column grid of [ProductCard]s whose rows size to their content, so
/// cards never clip at large text scales (no fixed tile heights).
class SliverProductGrid extends StatelessWidget {
  const SliverProductGrid({
    super.key,
    required this.products,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
    this.gap = AppSpacing.cardGap,
  });

  final List<Product> products;
  final EdgeInsets padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final rows = (products.length / 2).ceil();
    return SliverPadding(
      padding: padding,
      sliver: SliverList.separated(
        itemCount: rows,
        separatorBuilder: (_, _) => SizedBox(height: gap),
        itemBuilder: (context, row) => _ProductRow(
          left: products[row * 2],
          right: row * 2 + 1 < products.length ? products[row * 2 + 1] : null,
          gap: gap,
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.left, required this.right, required this.gap});

  final Product left;
  final Product? right;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ProductCard(product: left)),
          SizedBox(width: gap),
          Expanded(child: right == null ? const SizedBox.shrink() : ProductCard(product: right!)),
        ],
      ),
    );
  }
}
