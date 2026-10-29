import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../utils/formatters.dart';

class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.price,
    this.oldPrice,
    this.style,
    this.oldStyle,
    this.trailing,
  });

  final num price;
  final num? oldPrice;
  final TextStyle? style;
  final TextStyle? oldStyle;

  /// Extra widget after the prices (e.g. a discount badge).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final showOld = oldPrice != null && oldPrice! > price;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        Text(formatTaka(price), style: style ?? AppText.price),
        if (showOld)
          Text(
            formatTaka(oldPrice!),
            style: oldStyle ?? AppText.priceOld,
            semanticsLabel: 'was ${formatTaka(oldPrice!)}',
          ),
        ?trailing,
      ],
    );
  }
}
