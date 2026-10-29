import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// The 'zollo' wordmark, optionally with the rounded-square store mark.
class ZolloLogo extends StatelessWidget {
  const ZolloLogo({
    super.key,
    this.fontSize = 22,
    this.onPrimary = false,
    this.showMark = false,
    this.markSize = 88,
    this.gap = 14,
    this.vertical = true,
  });

  final double fontSize;

  /// White wordmark for use on a primary background.
  final bool onPrimary;
  final bool showMark;
  final double markSize;
  final double gap;

  /// Stack the mark above the wordmark (true) or beside it (false).
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final wordmark = Text(
      'zollo',
      style: AppText.custom(
        fontSize,
        FontWeight.w800,
        color: onPrimary ? AppColors.white : AppColors.primary,
        letterSpacing: -1,
        height: 1.1,
      ),
    );

    if (!showMark) return Semantics(header: true, child: wordmark);

    final mark = Container(
      width: markSize,
      height: markSize,
      decoration: BoxDecoration(
        color: onPrimary ? AppColors.white : AppColors.primary,
        borderRadius: BorderRadius.circular(markSize * 26 / 88),
      ),
      child: Icon(
        Icons.storefront_outlined,
        size: markSize * 46 / 88,
        color: onPrimary ? AppColors.primary : AppColors.white,
      ),
    );

    final children = [ExcludeSemantics(child: mark), SizedBox(width: gap, height: gap), wordmark];
    return Semantics(
      label: 'zollo',
      child: vertical
          ? Column(mainAxisSize: MainAxisSize.min, children: children)
          : Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
