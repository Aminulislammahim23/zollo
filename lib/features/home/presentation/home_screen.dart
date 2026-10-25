import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zollo/features/products/presentation/providers/products_provider.dart';

import 'widgets/home_header.dart';
import 'widgets/promo_banner.dart';
import 'widgets/category_row.dart';
import 'widgets/flash_sale_section.dart';
import 'widgets/just_for_you_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F7),
      body: SafeArea(
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (products) {
            return Column(
              children: [
                const HomeHeader(),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const PromoBanner(),
                      const CategoryRow(),
                      const SizedBox(height: 24),
                      FlashSaleSection(products: products),
                      const SizedBox(height: 24),
                      JustForYouSection(products: products),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
