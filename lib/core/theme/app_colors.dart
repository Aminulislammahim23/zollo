import 'package:flutter/material.dart';

/// zollo colour tokens. Screens must use these instead of raw hex values.
abstract final class AppColors {
  static const Color primary = Color(0xFF8A1C5E);
  static const Color primaryDark = Color(0xFF6B1247);
  static const Color primaryOnDark = Color(0xFF741650);
  static const Color primaryTint = Color(0xFFF8E7F0);
  static const Color onPrimaryMuted = Color(0xFFF4D6E5);

  static const Color accent = Color(0xFFF5B301);
  static const Color onAccent = Color(0xFF1B1A16);
  static const Color deep = Color(0xFF2A1023);

  static const Color ink = Color(0xFF1F1A1E);
  static const Color inkSoft = Color(0xFF43393F);
  static const Color muted = Color(0xFF6B6168);
  static const Color hint = Color(0xFF8E858B);

  static const Color background = Color(0xFFFAF7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF4EFF2);
  static const Color placeholder = Color(0xFFEFE9EC);

  static const Color border = Color(0xFFD6CDD2);
  static const Color divider = Color(0xFFEAE3E7);
  static const Color switchOff = Color(0xFFB9AFB5);

  static const Color discountBg = Color(0xFFFDE7C2);
  static const Color discountText = Color(0xFF7A4A00);
  static const Color star = Color(0xFFE9A100);
  static const Color warning = Color(0xFF9A5B00);
  static const Color error = Color(0xFF9B1C1C);
  static const Color errorBg = Color(0xFFFBE2E2);

  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);
}
