import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../domain/models/product.dart';
import '../../domain/product_filter.dart';
import '../providers/products_provider.dart';
import '../widgets/product_filter_sheet.dart';

/// `/products?category=<id>&q=<text>`.
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key, this.categoryId, this.query});

  final String? categoryId;
  final String? query;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late final TextEditingController _search = TextEditingController(text: widget.query ?? '');
  late ProductFilter _filter = ProductFilter(
    query: widget.query ?? '',
    categoryIds: {
      if (widget.categoryId != null && widget.categoryId!.isNotEmpty) widget.categoryId!,
    },
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _togglePriceSort() {
    setState(() {
      _filter = _filter.copyWith(
        sort: _filter.sort == ProductSort.priceLowToHigh
            ? ProductSort.priceHighToLow
            : ProductSort.priceLowToHigh,
      );
    });
  }

  void _clearFilters() {
    _search.clear();
    setState(() => _filter = const ProductFilter());
  }

  Future<void> _openFilters(List<Product> products, List<Category> categories) async {
    final maxPrice = products.fold<double>(0, (m, p) => p.price > m ? p.price : m);
    final result = await ProductFilterSheet.show(
      context,
      filter: _filter,
      categories: categories,
      maxPrice: maxPrice.ceilToDouble(),
    );
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final categoryNames = {for (final c in categories) c.id: c.name};

    final sort = _filter.sort;
    final priceLabel = switch (sort) {
      ProductSort.priceLowToHigh => 'Price ↑',
      ProductSort.priceHighToLow => 'Price ↓',
      ProductSort.popular => 'Price ↑/↓',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
            child: Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.m, AppSpacing.xs, AppSpacing.m),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back_ios_new, size: AppSpacing.iconSmall),
                        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                      ),
                      Expanded(
                        child: SearchField(
                          controller: _search,
                          hint: 'Search products',
                          onChanged: (v) => setState(() => _filter = _filter.copyWith(query: v)),
                        ),
                      ),
                      const CartIconButton(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                    child: Row(
                      children: [
                        AppChip(
                          label: 'Popular',
                          selected: sort == ProductSort.popular,
                          onTap: () => setState(() => _filter = _filter.copyWith(sort: ProductSort.popular)),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        AppChip(
                          label: priceLabel,
                          selected: sort != ProductSort.popular,
                          onTap: _togglePriceSort,
                        ),
                        const SizedBox(width: AppSpacing.s),
                        AppChip(
                          label: '4★ & up',
                          selected: _filter.minRating4,
                          onTap: () => setState(
                            () => _filter = _filter.copyWith(minRating4: !_filter.minRating4),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        AppChip(
                          label: 'Free delivery',
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Free delivery offers are coming soon.')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: AppSpacing.m),
                child: ShimmerGrid(count: 6),
              ),
              error: (error, _) => ErrorView(
                title: "Couldn't load products",
                error: error,
                onRetry: () => ref.invalidate(productsProvider),
              ),
              data: (products) {
                final results = _filter.apply(products, categoryNames: categoryNames);
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(productsProvider);
                    await ref.read(productsProvider.future).catchError((_) => <Product>[]);
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.xs, 0),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${results.length} ${results.length == 1 ? 'result' : 'results'}',
                                  style: AppText.custom(13, FontWeight.w500, color: AppColors.muted),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _openFilters(products, categories),
                                style: TextButton.styleFrom(foregroundColor: AppColors.ink),
                                icon: const Icon(Icons.tune, size: AppSpacing.iconSmall),
                                label: Text(
                                  _filter.categoryIds.isNotEmpty || _filter.minPrice != null || _filter.maxPrice != null
                                      ? 'Filters •'
                                      : 'Filters',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (results.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: Icons.search_off_outlined,
                            title: 'No products found',
                            message: 'Try a different search or filter.',
                            actionLabel: _filter.hasFilters ? 'Clear filters' : null,
                            onAction: _clearFilters,
                            actionVariant: AppButtonVariant.outline,
                          ),
                        )
                      else
                        SliverProductGrid(products: results),
                      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
