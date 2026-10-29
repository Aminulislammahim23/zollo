import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_text_field.dart';

/// Bangladeshi mobile number field with a fixed `+880` prefix.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    this.label = 'Phone',
    this.controller,
    this.required = false,
    this.onChanged,
    this.textInputAction,
    this.height = 52,
    this.labelStyle,
  });

  final String? label;
  final TextEditingController? controller;
  final bool required;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final double height;
  final TextStyle? labelStyle;

  static final RegExp _pattern = RegExp(r'^1[3-9]\d{8}$');

  /// Strips spaces, dashes and a `+880` / `880` / `0` prefix.
  static String normalize(String input) {
    var digits = input.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('880')) digits = digits.substring(3);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  static bool isValid(String input) => _pattern.hasMatch(normalize(input));

  /// `01712345678` → `+880 1712-345678`.
  static String display(String input) {
    final n = normalize(input);
    if (!_pattern.hasMatch(n)) return input;
    return '+880 ${n.substring(0, 4)}-${n.substring(4)}';
  }

  /// Value to store: `+8801712345678`.
  static String toE164(String input) => '+880${normalize(input)}';

  static String? validate(String? value, {bool required = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? 'Enter your phone number' : null;
    if (!isValid(text)) {
      return 'Enter a valid BD mobile number, e.g. 1712345678';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      labelStyle: labelStyle,
      controller: controller,
      height: height,
      hint: '1XXX-XXXXXX',
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\s-]')),
        LengthLimitingTextInputFormatter(13),
      ],
      onChanged: onChanged,
      validator: (v) => validate(v, required: required),
      prefix: Container(
        margin: const EdgeInsets.only(left: 1, right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        constraints: BoxConstraints(minHeight: height - 2),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.horizontal(left: Radius.circular(11)),
        ),
        child: Text(
          '+880',
          style: AppText.custom(15, FontWeight.w700, color: AppColors.inkSoft),
        ),
      ),
    );
  }
}
