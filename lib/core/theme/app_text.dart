import 'package:flutter/material.dart';

import 'app_colors.dart';

/// zollo typography (Manrope). Manrope is bundled as a variable font, so every
/// style sets the `wght` axis as well as [FontWeight].
abstract final class AppText {
  static const String fontFamily = 'Manrope';

  static TextStyle _m(
    double size,
    FontWeight weight, {
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: color,
    );
  }

  static final TextStyle display = _m(28, FontWeight.w800);
  static final TextStyle headline = _m(26, FontWeight.w800);
  static final TextStyle title = _m(18, FontWeight.w800);
  static final TextStyle section = _m(16, FontWeight.w800);
  static final TextStyle bodyStrong = _m(14, FontWeight.w700);
  static final TextStyle body = _m(15, FontWeight.w500, height: 1.5);
  static final TextStyle bodySmall = _m(13, FontWeight.w600);
  static final TextStyle label = _m(13, FontWeight.w700);
  static final TextStyle caption = _m(12, FontWeight.w500);
  static final TextStyle micro = _m(11, FontWeight.w600);
  static final TextStyle price =
      _m(16, FontWeight.w800, color: AppColors.primary);
  static final TextStyle priceOld = _m(
    12,
    FontWeight.w500,
    color: AppColors.muted,
    decoration: TextDecoration.lineThrough,
  );

  /// Builds an ad-hoc Manrope style for the few spec values that are not one
  /// of the named styles (e.g. the 40 / w800 splash wordmark).
  static TextStyle custom(
    double size,
    FontWeight weight, {
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) =>
      _m(
        size,
        weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        decoration: decoration,
      );

  static TextTheme get textTheme => TextTheme(
        displayLarge: display,
        displayMedium: display,
        displaySmall: display,
        headlineLarge: headline,
        headlineMedium: headline,
        headlineSmall: title,
        titleLarge: title,
        titleMedium: section,
        titleSmall: bodyStrong,
        bodyLarge: body,
        bodyMedium: _m(14, FontWeight.w500),
        bodySmall: caption,
        labelLarge: label,
        labelMedium: caption,
        labelSmall: micro,
      );
}

extension TextStyleX on TextStyle {
  TextStyle withColor(Color color) =>
      copyWith(color: color, decorationColor: color);

  TextStyle withWeight(FontWeight weight) => copyWith(
        fontWeight: weight,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
      );

  TextStyle withSize(double size) => copyWith(fontSize: size);
}
