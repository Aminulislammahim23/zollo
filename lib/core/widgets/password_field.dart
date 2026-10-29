import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_text_field.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    this.label = 'Password',
    this.controller,
    this.hint,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
  });

  final String? label;
  final TextEditingController? controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      controller: widget.controller,
      hint: widget.hint,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      keyboardType: TextInputType.visiblePassword,
      obscureText: _obscured,
      suffix: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: TextButton(
          onPressed: () => setState(() => _obscured = !_obscured),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppText.label,
          ),
          child: Text(
            _obscured ? 'Show' : 'Hide',
            semanticsLabel: _obscured ? 'Show password' : 'Hide password',
          ),
        ),
      ),
    );
  }
}
