import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/product_grid.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../products/domain/models/product.dart';

/// "Just for you" header plus a 2-column product grid, as slivers.
class JustForYouSection extends StatelessWidget {
  const JustForYouSection({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Just for you',
              onAction: () => context.push('/products'),
            ),
          ),
        ),
        SliverProductGrid(products: products),
      ],
    );
  }
}
