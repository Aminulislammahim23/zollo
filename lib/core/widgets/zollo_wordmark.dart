import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The painted 'Zollo' wordmark with the "ll" ligature.
///
/// Pass an [animation] running 0 → 1 over [introDuration] to play the intro;
/// without one the finished logo is painted.
class ZolloWordmark extends StatelessWidget {
  const ZolloWordmark({super.key, this.width = 260, this.animation});

  final double width;
  final Animation<double>? animation;

  static const Duration introDuration = Duration(milliseconds: 1600);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'zollo',
      image: true,
      child: CustomPaint(
        size: Size(width, width * 460 / 1145),
        painter: _WordmarkPainter(animation ?? kAlwaysCompleteAnimation),
      ),
    );
  }
}

class _Glyph {
  const _Glyph(this.path, this.center, this.start, {this.fromAbove = false});

  final Path path;
  final Offset center;
  final double start;
  final bool fromAbove;
}

Path _polygon(List<double> xy) {
  final points = <Offset>[
    for (var i = 0; i < xy.length; i += 2) Offset(xy[i], xy[i + 1]),
  ];
  return Path()..addPolygon(points, true);
}

Path _ring(double cx) {
  const cy = 237.0;
  return Path()
    ..fillType = PathFillType.evenOdd
    ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: 240, height: 272))
    ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: 114, height: 156));
}

final List<_Glyph> _glyphs = [
  _Glyph(
    _polygon(const [
      7, 8, 270, 8, 270, 68, 80, 310, 270, 310, //
      270, 370, 0, 370, 0, 310, 190, 68, 7, 68,
    ]),
    const Offset(135, 189),
    150,
  ),
  _Glyph(_ring(400), const Offset(400, 237), 220),
  _Glyph(
    _polygon(const [580, 0, 648, 0, 648, 277, 580, 345]),
    const Offset(614, 172),
    290,
  ),
  _Glyph(
    _polygon(const [732, 0, 795, 0, 795, 370, 578, 370, 633, 315, 732, 315]),
    const Offset(700, 185),
    360,
    fromAbove: true,
  ),
  _Glyph(_ring(962), const Offset(962, 237), 430),
];

class _WordmarkPainter extends CustomPainter {
  _WordmarkPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static const double _glyphDuration = 520;
  static const Rect _viewBox = Rect.fromLTWH(-30, -40, 1145, 460);

  double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * ZolloWordmark.introDuration.inMilliseconds;
    final d = Curves.easeOutCubic.transform(_seg(t, 700, 1100));
    final s = _seg(t, 860, 1100);
    final w = _seg(t, 950, 1450);

    canvas.save();
    final scale = size.width / _viewBox.width;
    canvas.scale(scale);
    canvas.translate(-_viewBox.left, -_viewBox.top);

    final sweeping = w > 0 && w < 1;
    if (sweeping) canvas.saveLayer(_viewBox, Paint());

    for (final glyph in _glyphs) {
      final p = _seg(t, glyph.start, glyph.start + _glyphDuration);
      if (p == 0) continue;
      final e = Curves.easeOutBack.transform(p);
      final opacity = Curves.easeOutCubic.transform((p * 1.6).clamp(0.0, 1.0));
      final dy = (glyph.fromAbove ? -90 : 60) * (1 - e);
      final k = 0.85 + 0.15 * e;

      canvas.save();
      canvas.translate(glyph.center.dx, glyph.center.dy + dy);
      canvas.scale(k);
      canvas.translate(-glyph.center.dx, -glyph.center.dy);

      if (d > 0) {
        canvas.drawPath(
          glyph.path.shift(Offset(6 * d, 12 * d)),
          Paint()
            ..color = AppColors.wordmarkShadow.withValues(
              alpha: 0.45 * d * opacity,
            )
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9 * d),
        );
      }

      canvas.drawPath(
        glyph.path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.wordmarkTop.withValues(alpha: opacity),
              AppColors.wordmarkBottom.withValues(alpha: opacity),
            ],
          ).createShader(const Rect.fromLTRB(0, 0, 1115, 370)),
      );
      canvas.restore();
    }

    if (sweeping) {
      // A slanted band of light that only lands on already-painted pixels.
      final x = -250 + 1600 * Curves.easeInOutCubic.transform(w);
      final band = Rect.fromLTRB(x - 180, -40, x + 180, 420);
      final fade = math.sin(math.pi * w);
      canvas.drawRect(
        _viewBox,
        Paint()
          ..blendMode = BlendMode.srcATop
          ..shader = LinearGradient(
            begin: const Alignment(-1, -0.35),
            end: const Alignment(1, 0.35),
            colors: [
              AppColors.white.withValues(alpha: 0),
              AppColors.white.withValues(alpha: 0.55 * fade),
              AppColors.white.withValues(alpha: 0),
            ],
          ).createShader(band),
      );
      canvas.restore();
    }

    if (s > 0 && s < 1) {
      canvas.drawLine(
        const Offset(560, 378),
        const Offset(660, 278),
        Paint()
          ..color = AppColors.white.withValues(
            alpha: math.sin(math.pi * s) * 0.9,
          )
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_WordmarkPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
