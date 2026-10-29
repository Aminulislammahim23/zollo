import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    this.controller,
    this.hint = 'Search products, brands and shops',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.height = 44,
    this.fillColor = AppColors.surfaceAlt,
    this.outlined = false,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// In [readOnly] mode the field acts as a button that opens search.
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final double height;
  final Color fillColor;

  /// Adds a 1.5px primary border (the active search screen).
  final bool outlined;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  TextEditingController? _own;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _own)?.removeListener(_onText);
      _controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    _own?.dispose();
    super.dispose();
  }

  void _onText() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: AppRadius.inputAll,
      borderSide: widget.outlined
          ? const BorderSide(
              color: AppColors.primary,
              width: AppBorders.selected,
            )
          : BorderSide.none,
    );

    final field = TextField(
      controller: _controller,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
      style: AppText.custom(14, FontWeight.w600),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppText.custom(14, FontWeight.w500, color: AppColors.hint),
        filled: true,
        fillColor: widget.fillColor,
        constraints: BoxConstraints(minHeight: widget.height),
        contentPadding: EdgeInsets.symmetric(
          vertical: (widget.height - 20) / 2,
        ),
        prefixIcon: const Icon(
          Icons.search,
          size: AppSpacing.iconInline,
          color: AppColors.muted,
        ),
        suffixIcon: !widget.readOnly && _controller.text.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                icon: const Icon(
                  Icons.close,
                  size: AppSpacing.iconSmall,
                  color: AppColors.muted,
                ),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                },
              )
            : null,
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );

    if (!widget.readOnly) return field;

    return Semantics(button: true, label: widget.hint, child: field);
  }
}
