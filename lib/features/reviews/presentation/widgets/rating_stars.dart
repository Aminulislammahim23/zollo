import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 28,
  });

  final int rating;
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;

        return IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: size,
          onPressed: onChanged == null
              ? null
              : () => onChanged!(value),
          icon: Icon(
            value <= rating
                ? Icons.star
                : Icons.star_border,
            color: Colors.amber,
          ),
        );
      }),
    );
  }
}