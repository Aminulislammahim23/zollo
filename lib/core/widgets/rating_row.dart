import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/formatters.dart';

class RatingRow extends StatelessWidget {
  const RatingRow({
    super.key,
    required this.rating,
    this.soldCount,
    this.location,
    this.iconSize = 13,
  });

  final double rating;
  final int? soldCount;
  final String? location;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final style = AppText.caption.withColor(AppColors.muted);
    final parts = <String>[
      if (rating > 0) rating.toStringAsFixed(1) else 'New',
      if (soldCount != null && soldCount! > 0) formatSold(soldCount!),
      ?location,
    ];
    return Row(
      children: [
        Icon(Icons.star_rounded, size: iconSize, color: AppColors.star),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            parts.join(' · '),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
