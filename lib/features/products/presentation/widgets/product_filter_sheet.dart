import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../categories/domain/category.dart';
import '../../domain/product_filter.dart';

/// Bottom sheet with a price-range slider and category checkboxes.
/// Pops with the updated [ProductFilter], or null when dismissed.
class ProductFilterSheet extends StatefulWidget {
  const ProductFilterSheet({
    super.key,
    required this.filter,
    required this.categories,
    required this.maxPrice,
  });

  final ProductFilter filter;
  final List<Category> categories;

  /// Highest price in the catalogue; the slider's upper bound.
  final double maxPrice;

  static Future<ProductFilter?> show(
    BuildContext context, {
    required ProductFilter filter,
    required List<Category> categories,
    required double maxPrice,
  }) {
    return showModalBottomSheet<ProductFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductFilterSheet(
        filter: filter,
        categories: categories,
        maxPrice: maxPrice,
      ),
    );
  }

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late RangeValues _range;
  late Set<String> _categories;

  double get _ceiling => widget.maxPrice <= 0 ? 1000 : widget.maxPrice;

  @override
  void initState() {
    super.initState();
    _range = RangeValues(
      (widget.filter.minPrice ?? 0).clamp(0, _ceiling),
      (widget.filter.maxPrice ?? _ceiling).clamp(0, _ceiling),
    );
    _categories = {...widget.filter.categoryIds};
  }

  void _apply() {
    final isFullRange = _range.start <= 0 && _range.end >= _ceiling;
    Navigator.of(context).pop(
      widget.filter.copyWith(
        categoryIds: _categories,
        minPrice: () => isFullRange || _range.start <= 0 ? null : _range.start,
        maxPrice: () =>
            isFullRange || _range.end >= _ceiling ? null : _range.end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                0,
                AppSpacing.l,
                AppSpacing.l,
              ),
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Filters', style: AppText.title)),
                    TextButton(
                      onPressed: () => setState(() {
                        _range = RangeValues(0, _ceiling);
                        _categories = {};
                      }),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                Text('Price range', style: AppText.bodyStrong),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${formatTaka(_range.start.round())} – ${formatTaka(_range.end.round())}',
                  style: AppText.caption.withColor(AppColors.muted),
                ),
                RangeSlider(
                  values: _range,
                  min: 0,
                  max: _ceiling,
                  divisions: 50,
                  labels: RangeLabels(
                    formatTaka(_range.start.round()),
                    formatTaka(_range.end.round()),
                  ),
                  onChanged: (v) => setState(() => _range = v),
                ),
                if (widget.categories.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.m),
                  Text('Category', style: AppText.bodyStrong),
                  const SizedBox(height: AppSpacing.xs),
                  for (final c in widget.categories)
                    CheckboxListTile(
                      value: _categories.contains(c.id),
                      onChanged: (v) => setState(() {
                        v == true
                            ? _categories.add(c.id)
                            : _categories.remove(c.id);
                      }),
                      title: Text(c.name, style: AppText.menuLabel),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.s,
                AppSpacing.l,
                AppSpacing.l,
              ),
              child: AppButton.primary(
                label: 'Show results',
                onPressed: _apply,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
