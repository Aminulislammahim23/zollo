import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../categories/presentation/providers/categories_provider.dart';

/// Five-column row: the first four categories plus "All".
class CategoryRow extends ConsumerWidget {
  const CategoryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    final tiles = categories.when(
      loading: () => List<Widget>.generate(
        5,
        (_) => const Column(
          children: [
            ShimmerBox(width: 52, height: 52, radius: AppRadius.banner),
            SizedBox(height: 6),
            ShimmerBox(width: 40, height: 10),
          ],
        ),
      ),
      // Categories are optional decoration on Home; "All" still works.
      error: (_, _) => [_AllTile()],
      data: (list) => [
        for (final c in list.take(4))
          _CategoryTile(
            icon: c.icon,
            label: c.name,
            onTap: () =>
                context.push('/products?category=${Uri.encodeComponent(c.id)}'),
          ),
        _AllTile(),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 5; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.s),
            Expanded(
              child: i < tiles.length ? tiles[i] : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AllTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CategoryTile(
      icon: Icons.apps_outlined,
      label: 'All',
      onTap: () => context.go('/categories'),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.tileAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.bannerAll,
                ),
                child: Icon(icon, size: 24, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppText.micro,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
