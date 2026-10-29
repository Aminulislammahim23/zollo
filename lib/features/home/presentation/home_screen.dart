import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../categories/presentation/providers/categories_provider.dart';
import '../../products/presentation/providers/products_provider.dart';
import 'widgets/category_row.dart';
import 'widgets/flash_sale_section.dart';
import 'widgets/home_header.dart';
import 'widgets/just_for_you_section.dart';
import 'widgets/promo_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(productsProvider);
    ref.invalidate(categoriesProvider);
    await ref.read(productsProvider.future).catchError((_) => <Never>[]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    const gap = SliverToBoxAdapter(child: SizedBox(height: 20));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const HomeHeader(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _refresh(ref),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.l),
                  ),
                  const SliverToBoxAdapter(child: PromoBanner()),
                  gap,
                  const SliverToBoxAdapter(child: CategoryRow()),
                  gap,
                  ...productsAsync.when(
                    loading: () => const [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.screen,
                          ),
                          child: ShimmerBox(
                            height: 200,
                            radius: AppRadius.banner,
                          ),
                        ),
                      ),
                      gap,
                      SliverToBoxAdapter(child: ShimmerGrid(shrinkWrap: true)),
                    ],
                    error: (error, _) => [
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 320,
                          child: ErrorView(
                            title: "Couldn't load products",
                            error: error,
                            onRetry: () => ref.invalidate(productsProvider),
                          ),
                        ),
                      ),
                    ],
                    data: (products) => products.isEmpty
                        ? [
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 320,
                                child: EmptyState(
                                  icon: Icons.storefront_outlined,
                                  title: 'No products yet',
                                  message: 'New products from our sellers will show up here.',
                                  actionLabel: 'Browse categories',
                                  onAction: () => context.go('/categories'),
                                ),
                              ),
                            ),
                          ]
                        : [
                            SliverToBoxAdapter(
                              child: FlashSaleSection(products: products),
                            ),
                            gap,
                            JustForYouSection(products: products),
                          ],
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
