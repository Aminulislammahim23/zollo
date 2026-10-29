import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../products/domain/models/product.dart';

class FlashSaleSection extends StatelessWidget {
  const FlashSaleSection({super.key, required this.products});

  final List<Product> products;

  /// Discounted products first, then the rest; three are shown.
  static List<Product> pick(List<Product> products) {
    final sorted = [...products.where((p) => p.inStock)]
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    return sorted.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = pick(products);
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: InfoCard(
        radius: AppRadius.banner,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'Flash Sale',
              trailing: const _Countdown(),
              onAction: () => context.push('/products'),
            ),
            const SizedBox(height: AppSpacing.m),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: i < items.length
                          ? _FlashItem(product: items[i])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashItem extends StatelessWidget {
  const _FlashItem({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final total = product.soldCount + product.stock;
    final soldFraction = total == 0 ? 0.0 : product.soldCount / total;

    return Semantics(
      button: true,
      label: '${product.title}, ${formatTaka(product.price)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push('/product-details', extra: product),
        borderRadius: AppRadius.tileAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppNetworkImage(
              url: product.imageUrl,
              height: 96,
              width: double.infinity,
              borderRadius: AppRadius.tileAll,
            ),
            const SizedBox(height: 6),
            Text(
              formatTaka(product.price),
              style: AppText.cardTitle.withColor(AppColors.primary),
            ),
            if (product.hasDiscount)
              Text(
                formatTaka(product.originalPrice!),
                style: AppText.priceOld.withSize(11),
              ),
            const Spacer(),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: soldFraction,
                minHeight: 6,
                backgroundColor: AppColors.discountBg,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Counts down to midnight; the flash sale resets daily.
class _Countdown extends StatefulWidget {
  const _Countdown();

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    setState(() => _left = midnight.difference(now));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final parts = [
      two(_left.inHours),
      two(_left.inMinutes % 60),
      two(_left.inSeconds % 60),
    ];
    return Semantics(
      label: 'Ends in ${_left.inHours} hours ${_left.inMinutes % 60} minutes',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.deep,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                parts[i],
                style: AppText.captionStrong.withColor(AppColors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
