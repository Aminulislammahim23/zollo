import 'package:flutter/material.dart';

class ZolloLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String text;

  const ZolloLogo({
    super.key,
    this.size = 80,
    this.showText = true,
    this.text = 'zollo',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(size * 0.22),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Green leaf/blade accents matching logo image
              Positioned(
                bottom: size * 0.12,
                right: size * 0.12,
                child: Container(
                  width: size * 0.4,
                  height: size * 0.25,
                  decoration: BoxDecoration(
                    color: const Color(0xFF76D743),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(size * 0.2),
                      bottomRight: Radius.circular(size * 0.2),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: size * 0.25,
                left: size * 0.12,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF76D743),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(size * 0.15),
                      bottomRight: Radius.circular(size * 0.15),
                    ),
                  ),
                ),
              ),
              // Center bold Z icon
              Icon(
                Icons.bolt,
                color: Colors.white,
                size: size * 0.6,
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: const Color(0xFF1E1E1E),
            ),
          ),
        ],
      ],
    );
  }
}
