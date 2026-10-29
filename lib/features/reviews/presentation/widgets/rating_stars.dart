import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Five stars. Read-only by default; pass [onChanged] to make each star a
/// 48dp button (write-review screen).
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 14,
  });

  /// May be fractional for averages (rounded to the nearest half star).
  final num rating;
  final ValueChanged<int>? onChanged;
  final double size;

  static const labels = ['Poor', 'Fair', 'Good', 'Very good', 'Excellent'];

  IconData _iconFor(int value) {
    if (rating >= value) return Icons.star_rounded;
    if (rating >= value - 0.5) return Icons.star_half_rounded;
    return Icons.star_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (onChanged == null) {
      return Semantics(
        label: '${rating.toStringAsFixed(1)} out of 5 stars',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var value = 1; value <= 5; value++)
              Icon(
                _iconFor(value),
                size: size,
                color: rating >= value - 0.5 ? AppColors.star : AppColors.switchOff,
              ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var value = 1; value <= 5; value++)
          SizedBox.square(
            dimension: 48,
            child: IconButton(
              tooltip: '$value star${value == 1 ? '' : 's'} – ${labels[value - 1]}',
              padding: EdgeInsets.zero,
              iconSize: size,
              onPressed: () => onChanged!(value),
              icon: Icon(
                value <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: value <= rating ? AppColors.star : AppColors.switchOff,
              ),
            ),
          ),
      ],
    );
  }
}
