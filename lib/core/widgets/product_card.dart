import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/products/domain/models/product.dart';
import '../../features/wishlist/presentation/widgets/wishlist_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'app_network_image.dart';
import 'discount_badge.dart';
import 'price_text.dart';
import 'rating_row.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.showWishlist = true,
    this.onTap,
    this.imageHeight = 150,
  });

  final Product product;
  final bool showWishlist;
  final VoidCallback? onTap;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: product.title,
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.cardAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap:
              onTap ?? () => context.push('/product-details', extra: product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: imageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(url: product.imageUrl),
                    if (product.hasDiscount)
                      Positioned(
                        top: AppSpacing.s,
                        right: AppSpacing.s,
                        child: DiscountBadge.percent(product.discountPercent),
                      )
                    else if (!product.inStock)
                      const Positioned(
                        top: AppSpacing.s,
                        right: AppSpacing.s,
                        child: DiscountBadge.outOfStock(),
                      ),
                    if (showWishlist)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: WishlistButton(
                          productId: product.id,
                          compact: true,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.title,
                      style: AppText.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    PriceText(
                      price: product.price,
                      oldPrice: product.originalPrice,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    RatingRow(
                      rating: product.rating,
                      soldCount: product.soldCount,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
