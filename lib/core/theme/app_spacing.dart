import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Side padding for every screen.
  static const double screen = 16;

  /// Padding inside cards (spec: 12–14).
  static const double card = 14;

  /// Gap between cards (spec: 10–12).
  static const double cardGap = 10;

  static const double tapTarget = 48;
  static const double iconBar = 22;
  static const double iconInline = 20;
  static const double iconSmall = 18;

  static const SizedBox gapXs = SizedBox(width: xs, height: xs);
  static const SizedBox gapS = SizedBox(width: s, height: s);
  static const SizedBox gapM = SizedBox(width: m, height: m);
  static const SizedBox gapL = SizedBox(width: l, height: l);
  static const SizedBox gapXl = SizedBox(width: xl, height: xl);
}

abstract final class AppRadius {
  static const double button = 12;
  static const double input = 12;
  static const double card = 14;
  static const double banner = 16;
  static const double tile = 10;
  static const double chip = 999;
  static const double badge = 6;

  static const BorderRadius buttonAll = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius inputAll = BorderRadius.all(Radius.circular(input));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius bannerAll = BorderRadius.all(
    Radius.circular(banner),
  );
  static const BorderRadius tileAll = BorderRadius.all(Radius.circular(tile));
  static const BorderRadius chipAll = BorderRadius.all(Radius.circular(chip));
  static const BorderRadius badgeAll = BorderRadius.all(Radius.circular(badge));
}

abstract final class AppBorders {
  static const double thin = 1;
  static const double selected = 1.5;
}
