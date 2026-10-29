import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// [CachedNetworkImage] with the zollo placeholder and error states.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.semanticLabel,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget fallback({bool broken = false}) => Container(
          width: width,
          height: height,
          color: AppColors.placeholder,
          alignment: Alignment.center,
          child: broken
              ? const Icon(Icons.broken_image_outlined, color: AppColors.hint, size: 24)
              : null,
        );

    final Widget image = url.isEmpty
        ? fallback(broken: true)
        : CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, _) => fallback(),
            errorWidget: (_, _, _) => fallback(broken: true),
          );

    final labelled = semanticLabel == null
        ? image
        : Semantics(image: true, label: semanticLabel, child: image);

    if (borderRadius == null) return labelled;
    return ClipRRect(borderRadius: borderRadius!, child: labelled);
  }
}
