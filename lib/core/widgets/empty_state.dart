import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionVariant = AppButtonVariant.primary,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primaryTint,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppButtonVariant actionVariant;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: iconColor),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(title, style: AppText.bodyStrong, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                style: AppText.caption.withColor(AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.l),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: actionVariant,
                fullWidth: false,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
