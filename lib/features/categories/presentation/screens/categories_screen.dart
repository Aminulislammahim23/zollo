import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../products/domain/models/product.dart';
import '../../domain/category.dart';
import '../providers/categories_provider.dart';

/// Bottom-nav tab 2: category rail on the left, the selected category's
/// products on the right (spec C8).
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.l,
              MediaQuery.paddingOf(context).top + 14,
              AppSpacing.l,
              14,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text('Categories', style: AppText.totalPrice),
                ),
                const SizedBox(height: AppSpacing.m),
                SearchField(
                  readOnly: true,
                  hint: 'Search in categories',
                  onTap: () => context.push('/search'),
                ),
              ],
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              loading: () => Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 104,
                    color: AppColors.surfaceAlt,
                    padding: const EdgeInsets.all(AppSpacing.s),
                    child: Column(
                      children: [
                        for (var i = 0; i < 6; i++) ...[
                          const ShimmerBox(height: 44),
                          const SizedBox(height: AppSpacing.s),
                        ],
                      ],
                    ),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Column(
                        children: [
                          ShimmerBox(height: 92, radius: AppRadius.card),
                          SizedBox(height: 14),
                          ShimmerBox(height: 200, radius: AppRadius.card),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              error: (error, _) => ErrorView(
                title: "Couldn't load categories",
                error: error,
                onRetry: () => ref.invalidate(categoriesProvider),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return EmptyState(
                    icon: Icons.category_outlined,
                    title: 'No categories yet',
                    message: 'Browse every product instead.',
                    actionLabel: 'See all products',
                    onAction: () => context.push('/products'),
                  );
                }
                final selected = categories.firstWhere(
                  (c) => c.id == _selectedId,
                  orElse: () => categories.first,
                );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CategoryRail(
                      categories: categories,
                      selectedId: selected.id,
                      onSelect: (c) => setState(() => _selectedId = c.id),
                    ),
                    Expanded(child: _CategoryPanel(category: selected)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Category> categories;
  final String selectedId;
  final ValueChanged<Category> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      color: AppColors.surfaceAlt,
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final c = categories[i];
          final isSelected = c.id == selectedId;
          return Semantics(
            selected: isSelected,
            button: true,
            child: Material(
              color: isSelected ? AppColors.surface : AppColors.transparent,
              child: InkWell(
                onTap: () => onSelect(c),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 60),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: AppSpacing.s,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.transparent,
                        width: 4,
                      ),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    c.name,
                    style: AppText.caption
                        .withWeight(
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                        )
                        .withColor(
                          isSelected ? AppColors.primary : AppColors.inkSoft,
                        ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryPanel extends ConsumerWidget {
  const _CategoryPanel({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsByCategoryProvider(category));

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.all(AppSpacing.l),
          decoration: const BoxDecoration(
            color: AppColors.deep,
            borderRadius: AppRadius.cardAll,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                category.name,
                style: AppText.section.withColor(AppColors.white),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Top deals this week',
                style: AppText.captionStrong.withColor(AppColors.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('Shop by type', style: AppText.rowTitle),
        const SizedBox(height: 14),
        productsAsync.when(
          loading: () => const ShimmerBox(height: 180, radius: AppRadius.card),
          error: (error, _) => SizedBox(
            height: 260,
            child: ErrorView(
              title: "Couldn't load products",
              error: error,
              onRetry: () =>
                  ref.invalidate(productsByCategoryProvider(category)),
            ),
          ),
          data: (products) => products.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Text(
                    'No products in ${category.name} yet.',
                    textAlign: TextAlign.center,
                    style: AppText.caption.withColor(AppColors.muted),
                  ),
                )
              : _ProductTypeGrid(products: products.take(9).toList()),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton.outline(
            label: 'See all ${category.name}',
            size: AppButtonSize.small,
            fullWidth: false,
            onPressed: () => context.push(
              '/products?category=${Uri.encodeComponent(category.id)}',
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductTypeGrid extends StatelessWidget {
  const _ProductTypeGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 14,
          children: [
            for (final p in products)
              SizedBox(
                width: width,
                child: Semantics(
                  button: true,
                  label: p.title,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => context.push('/product-details', extra: p),
                    borderRadius: AppRadius.tileAll,
                    child: Column(
                      children: [
                        AppNetworkImage(
                          url: p.imageUrl,
                          width: 64,
                          height: 64,
                          borderRadius: AppRadius.bannerAll,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppText.micro,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
