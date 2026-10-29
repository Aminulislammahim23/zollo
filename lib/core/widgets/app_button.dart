import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

enum AppButtonVariant { primary, outline, deal, danger }

enum AppButtonSize { regular, small }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.height,
    this.padding,
    this.backgroundColor,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.regular,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.height,
    this.padding,
  })  : variant = AppButtonVariant.primary,
        backgroundColor = null;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.regular,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.height,
    this.padding,
    this.backgroundColor,
  }) : variant = AppButtonVariant.outline;

  const AppButton.deal({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.regular,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.height,
    this.padding,
  })  : variant = AppButtonVariant.deal,
        backgroundColor = null;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.regular,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.height,
    this.padding,
    this.backgroundColor = AppColors.surface,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  /// Overrides the spec height (52 regular / 40 small), e.g. 48 in bottom bars.
  final double? height;
  final EdgeInsetsGeometry? padding;

  /// Fill for outline / danger variants (transparent by default).
  final Color? backgroundColor;

  bool get _small => size == AppButtonSize.small;

  double get _height => height ?? (_small ? 40 : 52);

  Color get _foreground => switch (variant) {
        AppButtonVariant.primary => AppColors.white,
        AppButtonVariant.outline => AppColors.primary,
        AppButtonVariant.deal => AppColors.onAccent,
        AppButtonVariant.danger => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final textStyle = AppText.custom(_small ? 13 : 15, FontWeight.w800);
    final iconSize = _small ? 16.0 : AppSpacing.iconInline;

    final child = loading
        ? SizedBox.square(
            dimension: _small ? 16 : 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize),
                const SizedBox(width: AppSpacing.s),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_small ? AppRadius.tile : AppRadius.button),
    );
    final minSize = Size(fullWidth ? double.infinity : 0, _height);
    final pad = padding ??
        EdgeInsets.symmetric(horizontal: _small ? AppSpacing.m : AppSpacing.l);

    final Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.deal:
        final isDeal = variant == AppButtonVariant.deal;
        button = FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: isDeal ? AppColors.accent : AppColors.primary,
            foregroundColor: _foreground,
            disabledBackgroundColor: loading
                ? (isDeal ? AppColors.accent : AppColors.primary)
                : AppColors.divider,
            disabledForegroundColor: loading ? _foreground : AppColors.muted,
            minimumSize: minSize,
            fixedSize: Size.fromHeight(_height),
            padding: pad,
            shape: shape,
            textStyle: textStyle,
          ).copyWith(
            overlayColor: WidgetStatePropertyAll(
              isDeal ? AppColors.onAccent.withValues(alpha: 0.08) : AppColors.primaryDark,
            ),
          ),
          child: child,
        );
      case AppButtonVariant.outline:
      case AppButtonVariant.danger:
        final color = variant == AppButtonVariant.danger ? AppColors.error : AppColors.primary;
        button = OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            backgroundColor: backgroundColor,
            disabledForegroundColor: loading ? color : AppColors.muted,
            minimumSize: minSize,
            fixedSize: Size.fromHeight(_height),
            padding: pad,
            shape: shape,
            textStyle: textStyle,
            side: BorderSide(
              color: enabled || loading ? color : AppColors.border,
              width: AppBorders.selected,
            ),
          ),
          child: child,
        );
    }

    return Semantics(button: true, enabled: enabled, child: button);
  }
}
