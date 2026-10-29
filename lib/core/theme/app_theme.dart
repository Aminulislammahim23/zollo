import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text.dart';

class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.primaryTint,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      surfaceContainerHighest: AppColors.surfaceAlt,
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: AppColors.errorBg,
      onErrorContainer: AppColors.error,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    );

    final buttonText = AppText.custom(15, FontWeight.w800);
    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.buttonAll);
    const buttonSize = Size(64, 52);

    OutlineInputBorder inputBorder(Color color, [double width = AppBorders.thin]) {
      return OutlineInputBorder(
        borderRadius: AppRadius.inputAll,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppText.fontFamily,
      textTheme: AppText.textTheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.ink, size: AppSpacing.iconBar),
        titleTextStyle: AppText.title,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink, size: AppSpacing.iconInline),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        hintStyle: AppText.custom(15, FontWeight.w500, color: AppColors.hint),
        labelStyle: AppText.label,
        errorStyle: AppText.caption.withColor(AppColors.error),
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        disabledBorder: inputBorder(AppColors.divider),
        focusedBorder: inputBorder(AppColors.primary, AppBorders.selected),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, AppBorders.selected),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.divider,
          disabledForegroundColor: AppColors.muted,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
          side: const BorderSide(color: AppColors.primary, width: AppBorders.selected),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppText.label,
          minimumSize: const Size(48, 48),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryTint,
        labelStyle: AppText.label,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.white),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColors.switchOff
              : states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.border,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.switchOff,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.transparent),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.banner)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.bannerAll),
        titleTextStyle: AppText.title,
        contentTextStyle: AppText.body.withColor(AppColors.inkSoft),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.bodySmall.withColor(AppColors.white),
        actionTextColor: AppColors.accent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonAll),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.divider,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.muted,
        labelStyle: AppText.custom(13, FontWeight.w800),
        unselectedLabelStyle: AppText.custom(13, FontWeight.w600),
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.divider,
        tabAlignment: TabAlignment.start,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.divider,
        thumbColor: AppColors.primary,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.ink,
        titleTextStyle: AppText.custom(14, FontWeight.w600),
        subtitleTextStyle: AppText.caption.withColor(AppColors.muted),
      ),
    );
  }
}
