import 'package:flutter/material.dart';

import '../../features/orders/domain/models/order_model.dart';
import '../../features/products/domain/models/product.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../utils/formatters.dart';
import '../widgets/widgets.dart';

/// Debug-only catalogue of every token and shared widget (`/style-preview`).
class StylePreviewScreen extends StatefulWidget {
  const StylePreviewScreen({super.key});

  @override
  State<StylePreviewScreen> createState() => _StylePreviewScreenState();
}

class _StylePreviewScreenState extends State<StylePreviewScreen> {
  int _qty = 1;
  bool _chip = true;

  static const _colors = <String, Color>{
    'primary': AppColors.primary,
    'primaryDark': AppColors.primaryDark,
    'primaryOnDark': AppColors.primaryOnDark,
    'primaryTint': AppColors.primaryTint,
    'onPrimaryMuted': AppColors.onPrimaryMuted,
    'accent': AppColors.accent,
    'onAccent': AppColors.onAccent,
    'deep': AppColors.deep,
    'ink': AppColors.ink,
    'inkSoft': AppColors.inkSoft,
    'muted': AppColors.muted,
    'hint': AppColors.hint,
    'background': AppColors.background,
    'surface': AppColors.surface,
    'surfaceAlt': AppColors.surfaceAlt,
    'placeholder': AppColors.placeholder,
    'border': AppColors.border,
    'divider': AppColors.divider,
    'switchOff': AppColors.switchOff,
    'discountBg': AppColors.discountBg,
    'discountText': AppColors.discountText,
    'star': AppColors.star,
    'warning': AppColors.warning,
    'error': AppColors.error,
    'errorBg': AppColors.errorBg,
  };

  static final _styles = <String, TextStyle>{
    'display': AppText.display,
    'headline': AppText.headline,
    'title': AppText.title,
    'section': AppText.section,
    'bodyStrong': AppText.bodyStrong,
    'body': AppText.body,
    'bodySmall': AppText.bodySmall,
    'label': AppText.label,
    'caption': AppText.caption,
    'micro': AppText.micro,
    'price': AppText.price,
    'priceOld': AppText.priceOld,
  };

  static const _sample = Product(
    id: 'preview',
    title: 'Wireless Bluetooth Earbuds with charging case',
    description: '',
    price: 1850,
    imageUrl: '',
    category: 'Electronics',
    rating: 4.6,
    stock: 12,
    originalPrice: 2400,
    soldCount: 3400,
  );

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.s),
        child: Text(text, style: AppText.section),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Style preview'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.xxl),
        children: [
          _heading('Colours'),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final entry in _colors.entries)
                SizedBox(
                  width: 104,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: entry.value,
                          borderRadius: AppRadius.tileAll,
                          border: Border.all(color: AppColors.divider),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(entry.key, style: AppText.micro),
                    ],
                  ),
                ),
            ],
          ),
          _heading('Text styles'),
          for (final entry in _styles.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Text('${entry.key} · ${formatTaka(2450)}', style: entry.value),
            ),
          _heading('Buttons'),
          AppButton.primary(label: 'Primary', onPressed: () {}),
          AppSpacing.gapS,
          AppButton.outline(label: 'Outline', onPressed: () {}),
          AppSpacing.gapS,
          AppButton.deal(label: 'Deal', icon: Icons.bolt_outlined, onPressed: () {}),
          AppSpacing.gapS,
          AppButton.danger(label: 'Danger', onPressed: () {}),
          AppSpacing.gapS,
          const AppButton.primary(label: 'Loading', loading: true, onPressed: null),
          AppSpacing.gapS,
          const AppButton.primary(label: 'Disabled', onPressed: null),
          AppSpacing.gapS,
          Row(
            children: [
              AppButton.primary(
                label: 'Small',
                size: AppButtonSize.small,
                fullWidth: false,
                onPressed: () {},
              ),
              AppSpacing.gapS,
              AppButton.outline(
                label: 'Small outline',
                size: AppButtonSize.small,
                fullWidth: false,
                onPressed: () {},
              ),
            ],
          ),
          _heading('Inputs'),
          const AppTextField(label: 'Email', hint: 'you@example.com'),
          AppSpacing.gapM,
          const PasswordField(),
          AppSpacing.gapM,
          const PhoneField(),
          AppSpacing.gapM,
          const SearchField(),
          _heading('Chips & badges'),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              AppChip(label: 'Selected', selected: _chip, onTap: () => setState(() => _chip = !_chip)),
              AppChip(label: 'Unselected', selected: !_chip, onTap: () => setState(() => _chip = !_chip)),
              const DiscountBadge.percent(23),
              const DiscountBadge.priceDrop(),
              const DiscountBadge.outOfStock(),
            ],
          ),
          _heading('Price, rating, status'),
          const PriceText(price: 1850, oldPrice: 2400),
          AppSpacing.gapS,
          const RatingRow(rating: 4.6, soldCount: 3400, location: 'Dhaka'),
          AppSpacing.gapS,
          Wrap(
            spacing: AppSpacing.m,
            children: [for (final s in OrderStatus.values) StatusText(s)],
          ),
          _heading('Quantity stepper'),
          Align(
            alignment: Alignment.centerLeft,
            child: QuantityStepper(
              value: _qty,
              max: 5,
              onIncrement: () => setState(() => _qty++),
              onDecrement: () => setState(() => _qty--),
            ),
          ),
          _heading('Section header & product card'),
          SectionHeader(title: 'Just for you', onAction: () {}),
          SizedBox(
            width: 180,
            child: ProductCard(product: _sample, showWishlist: false, onTap: () {}),
          ),
          _heading('Info card'),
          const InfoCard(child: Text('InfoCard: white, radius 14, padding 14')),
          _heading('Shimmer'),
          const ShimmerBox(height: 60),
          _heading('Empty & error'),
          const SizedBox(
            height: 260,
            child: EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: "Add products you like and they'll show up here.",
            ),
          ),
          SizedBox(
            height: 260,
            child: ErrorView(message: 'Could not load products.', onRetry: () {}),
          ),
          _heading('Logo'),
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.all(AppSpacing.l),
            child: const ZolloLogo(onPrimary: true, showMark: true, markSize: 56),
          ),
          AppSpacing.gapS,
          const ZolloLogo(fontSize: 28),
        ],
      ),
    );
  }
}
