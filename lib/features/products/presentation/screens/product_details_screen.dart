import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../address/presentation/providers/address_provider.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../reviews/domain/review_summary.dart';
import '../../../reviews/presentation/widgets/rating_stars.dart';
import '../../../reviews/providers/review_providers.dart';
import '../../../wishlist/presentation/widgets/wishlist_button.dart';
import '../../domain/models/product.dart';

/// `/product-details` (extra: Product), spec C9.
class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  // TODO(backend): read options from a product_variants table.
  static const colours = ['Black', 'White', 'Navy'];

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  String _colour = ProductDetailsScreen.colours.first;
  bool _descriptionExpanded = false;

  Product get product => widget.product;

  String get _variant => 'Colour: $_colour';

  void _addToCart() {
    ref.read(cartProvider.notifier).addToCart(product, variant: _variant);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.title} added to cart'),
        action: SnackBarAction(
          label: 'View cart',
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }

  void _buyNow() {
    final inCart = ref.read(cartProvider).containsKey(product.id);
    if (!inCart) {
      ref.read(cartProvider.notifier).addToCart(product, variant: _variant);
    }
    context.go('/cart');
  }

  Future<void> _share() async {
    await Clipboard.setData(
      ClipboardData(text: '${AppConstants.productShareBaseUrl}/${product.id}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Product link copied.')));
  }

  Future<void> _chatWithSeller() async {
    if (ref.read(currentUserProvider) == null) {
      context.push('/login');
      return;
    }
    final conversation = await ref
        .read(chatRepositoryProvider)
        .conversationForProduct(product);
    if (!mounted) return;
    context.push('/messages/${conversation.id}');
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(productReviewsProvider(product.id));
    final summary = ReviewSummary.from(reviewsAsync.value ?? const []);
    final rating = summary.count > 0 ? summary.average : product.rating;
    final ratingCount = summary.count > 0 ? summary.count : product.ratingCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ImageHeader(product: product, onShare: _share),
          _Section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PriceText(
                  price: product.price,
                  oldPrice: product.originalPrice,
                  style: AppText.headline.withColor(AppColors.primary),
                  oldStyle: AppText.priceOld.withSize(14),
                  trailing: product.hasDiscount
                      ? DiscountBadge.percent(product.discountPercent)
                      : null,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  product.title,
                  style: AppText.productTitle.copyWith(height: 1.35),
                ),
                const SizedBox(height: AppSpacing.s),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.star,
                    ),
                    Text(
                      rating > 0 ? rating.toStringAsFixed(1) : 'New',
                      style: AppText.label,
                    ),
                    Text(
                      '($ratingCount ${ratingCount == 1 ? 'rating' : 'ratings'})',
                      style: AppText.meta.withColor(AppColors.muted),
                    ),
                    if (product.soldCount > 0)
                      Text(
                        '· ${formatSold(product.soldCount)}',
                        style: AppText.meta.withColor(AppColors.muted),
                      ),
                  ],
                ),
                if (!product.inStock) ...[
                  const SizedBox(height: AppSpacing.s),
                  const DiscountBadge.outOfStock(),
                ] else if (product.stock <= 5) ...[
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Only ${product.stock} left in stock',
                    style: AppText.label.withColor(AppColors.warning),
                  ),
                ],
              ],
            ),
          ),
          _Section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Colour', style: AppText.bodyStrong),
                    const Spacer(),
                    Text(
                      _colour,
                      style: AppText.bodyMedium.withColor(AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    for (final c in ProductDetailsScreen.colours)
                      _OptionChip(
                        label: c,
                        selected: c == _colour,
                        onTap: () => setState(() => _colour = c),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const _Section(child: _DeliveryInfo()),
          _Section(
            child: _ReviewsSummary(
              product: product,
              rating: rating,
              count: summary.count,
              loading: reviewsAsync.isLoading,
            ),
          ),
          if (product.description.trim().isNotEmpty)
            _Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description', style: AppText.section),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    product.description,
                    maxLines: _descriptionExpanded ? null : 4,
                    overflow: _descriptionExpanded
                        ? null
                        : TextOverflow.ellipsis,
                    style: AppText.body.withColor(AppColors.inkSoft),
                  ),
                  if (product.description.length > 160)
                    TextButton(
                      onPressed: () => setState(
                        () => _descriptionExpanded = !_descriptionExpanded,
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(
                        _descriptionExpanded ? 'Show less' : 'Read more',
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.l),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 48,
                  child: OutlinedButton(
                    onPressed: _chatWithSeller,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size.square(48),
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: AppSpacing.iconInline,
                      semanticLabel: 'Chat with seller',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (product.inStock) ...[
                  Expanded(
                    child: AppButton.outline(
                      label: 'Add to cart',
                      height: 48,
                      onPressed: _addToCart,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton.primary(
                      label: 'Buy now',
                      height: 48,
                      onPressed: _buyNow,
                    ),
                  ),
                ] else
                  const Expanded(
                    child: AppButton.danger(
                      label: 'Out of stock',
                      height: 48,
                      onPressed: null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: 14,
      ),
      child: child,
    );
  }
}

class _ImageHeader extends StatefulWidget {
  const _ImageHeader({required this.product, required this.onShare});

  final Product product;
  final VoidCallback onShare;

  @override
  State<_ImageHeader> createState() => _ImageHeaderState();
}

class _ImageHeaderState extends State<_ImageHeader> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    // TODO(backend): product_images table; only the main image exists today.
    final images = [widget.product.imageUrl];
    final top = MediaQuery.paddingOf(context).top;

    Widget circle({
      required String tooltip,
      required IconData icon,
      required VoidCallback onPressed,
    }) {
      return IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSpacing.tapTarget),
        ),
        icon: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: AppSpacing.iconSmall, color: AppColors.ink),
        ),
      );
    }

    return SizedBox(
      height: 330 + top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppColors.placeholder,
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => AppNetworkImage(
                url: images[i],
                semanticLabel: widget.product.title,
              ),
            ),
          ),
          Positioned(
            top: top + 12,
            left: 8,
            right: 8,
            child: Row(
              children: [
                circle(
                  tooltip: 'Back',
                  icon: Icons.arrow_back_ios_new,
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                ),
                const Spacer(),
                circle(
                  tooltip: 'Copy product link',
                  icon: Icons.share_outlined,
                  onPressed: widget.onShare,
                ),
                const CartIconButton(circle: true),
                WishlistButton(productId: widget.product.id, circle: true),
              ],
            ),
          ),
          Positioned(
            right: AppSpacing.l,
            bottom: AppSpacing.l,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.deep,
                borderRadius: AppRadius.chipAll,
              ),
              child: Text(
                '${_page + 1} / ${images.length}',
                style: AppText.captionStrong.withColor(AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primaryTint : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.tileAll,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.tileAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: AppText.menuLabel
                      .withWeight(selected ? FontWeight.w700 : FontWeight.w600)
                      .withColor(selected ? AppColors.primary : AppColors.ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryInfo extends ConsumerWidget {
  const _DeliveryInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(currentUserProvider) != null;
    final address = signedIn ? ref.watch(defaultAddressProvider).value : null;
    final area = address == null
        ? 'Dhaka'
        : (address.area.isNotEmpty ? address.area : address.district);

    Widget row(IconData icon, String title, [String? note]) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSpacing.iconInline, color: AppColors.primary),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.meta.withWeight(
                    note == null ? FontWeight.w600 : FontWeight.w700,
                  ),
                ),
                if (note != null)
                  Text(note, style: AppText.meta.withColor(AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        row(
          Icons.local_shipping_outlined,
          'Standard delivery to $area · ${formatTaka(ref.watch(deliveryFeeProvider))}',
          'Arrives in 2–4 days',
        ),
        row(
          Icons.account_balance_wallet_outlined,
          'Cash on delivery available',
        ),
        row(
          Icons.assignment_return_outlined,
          '${AppConstants.returnWindowDays}-day easy return',
        ),
      ],
    );
  }
}

class _ReviewsSummary extends ConsumerWidget {
  const _ReviewsSummary({
    required this.product,
    required this.rating,
    required this.count,
    required this.loading,
  });

  final Product product;
  final double rating;
  final int count;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReview =
        ref.watch(canUserReviewProvider(product.id)).value ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Ratings & reviews', style: AppText.section)),
            TextButton(
              onPressed: () => context.push('/product-reviews', extra: product),
              child: Text('See all ($count)'),
            ),
          ],
        ),
        if (loading)
          const ShimmerBox(height: 20, width: 160)
        else
          Row(
            children: [
              Text(
                rating > 0 ? rating.toStringAsFixed(1) : '–',
                style: AppText.bannerTitle,
              ),
              const SizedBox(width: AppSpacing.s),
              RatingStars(rating: rating, size: 16),
              const SizedBox(width: AppSpacing.s),
              Flexible(
                child: Text(
                  count == 0
                      ? 'No reviews yet'
                      : '$count ${count == 1 ? 'review' : 'reviews'}',
                  style: AppText.caption.withColor(AppColors.muted),
                ),
              ),
            ],
          ),
        if (canReview) ...[
          const SizedBox(height: AppSpacing.m),
          AppButton.outline(
            label: 'Write a review',
            size: AppButtonSize.small,
            fullWidth: false,
            icon: Icons.edit_outlined,
            onPressed: () => context.push('/write-review', extra: product),
          ),
        ],
      ],
    );
  }
}
