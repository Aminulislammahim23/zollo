import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.max,
    required this.onIncrement,
    required this.onDecrement,
    this.min = 1,
  });

  final int value;
  final int min;
  final int max;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, String tooltip, VoidCallback? onPressed) {
      // 36×36 visual box inside a 48dp hit area (rule A2.5).
      return SizedBox(
        width: 36,
        height: 36,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          iconSize: AppSpacing.iconSmall,
          color: AppColors.ink,
          disabledColor: AppColors.switchOff,
          style: IconButton.styleFrom(
            minimumSize: const Size(36, 36),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          icon: Icon(icon),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.tileAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove, 'Decrease quantity', value > min ? onDecrement : null),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppText.custom(14, FontWeight.w700),
              semanticsLabel: 'Quantity $value',
            ),
          ),
          button(Icons.add, 'Increase quantity', value < max ? onIncrement : null),
        ],
      ),
    );
  }
}
