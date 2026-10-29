import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../products/domain/models/product.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../providers/wishlist_provider.dart';

/// `/wishlist`, spec C16.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final productsAsync = ref.watch(productsProvider);
    final lookup = ref.watch(productLookupProvider);
    final count = wishlist.value?.length ?? 0;
    final signedIn = ref.watch(currentUserProvider) != null;

    Future<void> remove(String productId) async {
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

    Future<void> moveToCart(Product product) async {
      ref.read(cartProvider.notifier).addToCart(product);
      await remove(product.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.title} moved to your cart'),
          action: SnackBarAction(
            label: 'View cart',
            onPressed: () => context.go('/cart'),
          ),
        ),
      );
    }

    final Widget body;
    if (!signedIn) {
      body = EmptyState(
        icon: Icons.favorite_border,
        title: 'Log in to see your wishlist',
        message: 'Save products you love and find them on any device.',
        actionLabel: 'Log in',
        onAction: () => context.push('/login'),
      );
    } else if (wishlist.isLoading || productsAsync.isLoading) {
      body = const ShimmerList(itemHeight: 120);
    } else if (wishlist.hasError || productsAsync.hasError) {
      body = ErrorView(
        title: "Couldn't load your wishlist",
        error: wishlist.error ?? productsAsync.error,
        onRetry: () {
          ref.read(wishlistProvider.notifier).reload();
          ref.invalidate(productsProvider);
        },
      );
    } else if (count == 0) {
      body = EmptyState(
        icon: Icons.favorite_border,
        title: 'Your wishlist is empty',
        message: 'Tap the heart on any product to save it here.',
        actionLabel: 'Browse products',
        onAction: () => context.push('/products'),
      );
    } else {
      final ids = wishlist.value!.toList();
      body = RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(wishlistProvider.notifier).reload(),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.m),
          itemCount: ids.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.cardGap),
          itemBuilder: (context, i) {
            final product = lookup[ids[i]];
            if (product == null) {
              return _UnavailableCard(onRemove: () => remove(ids[i]));
            }
            return _WishlistCard(
              product: product,
              onRemove: () => remove(product.id),
              onMoveToCart: () => moveToCart(product),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppTopBar(
        title: count > 0 ? 'Wishlist ($count)' : 'Wishlist',
        fallbackRoute: '/account',
      ),
      body: body,
    );
  }
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({
    required this.product,
    required this.onRemove,
    required this.onMoveToCart,
  });

  final Product product;
  final VoidCallback onRemove;
  final VoidCallback onMoveToCart;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push('/product-details', extra: product),
            borderRadius: AppRadius.tileAll,
            child: AppNetworkImage(
              url: product.imageUrl,
              width: 96,
              height: 96,
              borderRadius: AppRadius.tileAll,
              semanticLabel: product.title,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
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
                const SizedBox(height: AppSpacing.xs),
                PriceText(
                  price: product.price,
                  oldPrice: product.originalPrice,
                ),
                if (!product.inStock) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const DiscountBadge.outOfStock(),
                ],
                const SizedBox(height: AppSpacing.s),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox.square(
                      dimension: 40,
                      child: OutlinedButton(
                        onPressed: onRemove,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size.square(40),
                          tapTargetSize: MaterialTapTargetSize.padded,
                          foregroundColor: AppColors.muted,
                          side: const BorderSide(color: AppColors.border),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.tileAll,
                          ),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          size: AppSpacing.iconInline,
                          semanticLabel:
                              'Remove ${product.title} from wishlist',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Flexible(
                      child: AppButton.primary(
                        label: 'Move to cart',
                        size: AppButtonSize.small,
                        fullWidth: false,
                        onPressed: product.inStock ? onMoveToCart : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.onRemove});

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              'This product is no longer available.',
              style: AppText.meta.withColor(AppColors.muted),
            ),
          ),
          TextButton(onPressed: onRemove, child: const Text('Remove')),
        ],
      ),
    );
  }
}
