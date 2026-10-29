import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../domain/address_model.dart';

/// Address book card, spec C22.
class AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback? onEdit;
  final VoidCallback? onSetDefault;
  final VoidCallback? onTap;

  /// Select mode shows a radio; [isSelected] is its value.
  final bool selecting;
  final bool isSelected;

  const AddressCard({
    super.key,
    required this.address,
    this.onEdit,
    this.onSetDefault,
    this.onTap,
    this.selecting = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = address.label.toUpperCase();
    final isHome = label == 'HOME';

    Widget tag(String text, {required Color fg, required Color bg}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: 2),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadius.badgeAll),
          child: Text(text, style: AppText.custom(11, FontWeight.w800, color: fg)),
        );

    final highlighted = selecting ? isSelected : address.isDefault;

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardAll,
        side: BorderSide(
          color: highlighted ? AppColors.primary : AppColors.divider,
          width: highlighted ? AppBorders.selected : AppBorders.thin,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.card),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        tag(
                          label.isEmpty ? 'OTHER' : label,
                          fg: isHome ? AppColors.white : AppColors.inkSoft,
                          bg: isHome ? AppColors.primary : AppColors.surfaceAlt,
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 6),
                          tag('Default', fg: AppColors.primary, bg: AppColors.primaryTint),
                        ],
                        const Spacer(),
                        if (onEdit != null && !selecting)
                          TextButton(
                            onPressed: onEdit,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 36),
                              tapTargetSize: MaterialTapTargetSize.padded,
                            ),
                            child: Text('Edit', semanticsLabel: 'Edit ${address.label} address'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${address.fullName} · ${PhoneField.display(address.phone)}',
                      style: AppText.bodyStrong,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      address.displayAddress,
                      style: AppText.custom(13, FontWeight.w500, color: AppColors.muted, height: 1.45),
                    ),
                    if (!address.isDefault && onSetDefault != null && !selecting)
                      TextButton(
                        onPressed: onSetDefault,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text('Set as default'),
                      ),
                  ],
                ),
              ),
              if (selecting)
                Radio<String>(value: address.id),
            ],
          ),
        ),
      ),
    );
  }
}
