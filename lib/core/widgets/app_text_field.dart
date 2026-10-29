import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.prefix,
    this.suffix,
    this.labelTrailing,
    this.fillColor,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.height = 52,
    this.labelStyle,
    this.focusNode,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final Widget? prefix;
  final Widget? suffix;

  /// Shown at the right end of the label row (e.g. a "Verified" tag).
  final Widget? labelTrailing;
  final Color? fillColor;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  /// Minimum height of a single-line input (52 by spec, 46 on address forms).
  final double height;
  final TextStyle? labelStyle;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final multiline = maxLines > 1;
    final vertical = multiline ? 14.0 : (height - 20) / 2;

    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      keyboardType: multiline ? TextInputType.multiline : keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      autofocus: autofocus,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: AppText.custom(15, FontWeight.w600),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: fillColor ?? AppColors.surface,
        constraints: multiline ? null : BoxConstraints(minHeight: height),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: vertical,
        ),
        prefixIcon: prefix,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        counterStyle: AppText.caption.withColor(AppColors.hint),
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Text(label!, style: labelStyle ?? AppText.label)),
            ?labelTrailing,
          ],
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
