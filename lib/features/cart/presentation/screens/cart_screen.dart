import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_item_tile.dart';

/// Bottom-nav tab 3, spec C10.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _editing = false;
  final Set<String> _selected = {};

  void _toggleEditing() => setState(() {
        _editing = !_editing;
        _selected.clear();
      });

  void _deleteSelected() {
    final cart = ref.read(cartProvider.notifier);
    for (final id in _selected) {
      cart.removeItem(id);
    }
    final count = _selected.length;
    setState(() {
      _selected.clear();
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed $count ${count == 1 ? 'item' : 'items'} from your cart.')),
    );
  }

  void _checkout(double subtotal) {
    if (ref.read(currentUserProvider) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Log in to check out.'),
          action: SnackBarAction(label: 'Log in', onPressed: () => context.push('/login')),
        ),
      );
      return;
    }
    context.push('/checkout', extra: {
      'subtotal': subtotal,
      'deliveryCharge': AppConstants.deliveryFee,
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final items = cart.values.toList();
    final count = ref.watch(cartItemCountProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final total = subtotal + (items.isEmpty ? 0 : AppConstants.deliveryFee);

    if (items.isEmpty && _editing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _editing = false);
      });
    }

    return Scaffold(
      appBar: AppTopBar(
        title: items.isEmpty ? 'My cart' : 'My cart ($count)',
        showBack: false,
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: _toggleEditing,
              child: Text(_editing ? 'Done' : 'Edit'),
            ),
        ],
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: "Add products you like and they'll show up here.",
              actionLabel: 'Start shopping',
              onAction: () => context.go('/home'),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.m),
              children: [
                InfoCard(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                            child: Divider(),
                          ),
                        CartItemTile(
                          item: items[i],
                          selecting: _editing,
                          selected: _selected.contains(items[i].product.id),
                          onSelectedChanged: (v) => setState(() {
                            v ? _selected.add(items[i].product.id) : _selected.remove(items[i].product.id);
                          }),
                          onIncrement: () => ref.read(cartProvider.notifier).increment(items[i].product.id),
                          onDecrement: () => ref.read(cartProvider.notifier).decrement(items[i].product.id),
                          onRemove: () => ref.read(cartProvider.notifier).removeItem(items[i].product.id),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                const _VoucherRow(),
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
              child: _editing
                  ? AppButton.danger(
                      label: _selected.isEmpty ? 'Select items to delete' : 'Delete (${_selected.length})',
                      icon: Icons.delete_outline,
                      height: 50,
                      onPressed: _selected.isEmpty ? null : _deleteSelected,
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Total incl. delivery', style: AppText.caption.withColor(AppColors.muted)),
                              Text(
                                formatTaka(total),
                                style: AppText.custom(20, FontWeight.w800, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        AppButton.primary(
                          label: 'Checkout ($count)',
                          fullWidth: false,
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                          onPressed: () => _checkout(subtotal),
                        ),
                      ],
                    ),
            ),
    );
  }
}

class _VoucherRow extends StatelessWidget {
  const _VoucherRow();

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      color: AppColors.primary,
      radius: AppRadius.card,
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.cardAll,
        child: InkWell(
          borderRadius: AppRadius.cardAll,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vouchers are coming soon')),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: AppSpacing.iconInline, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Apply a voucher',
                      style: AppText.custom(14, FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                  Text('Coming soon', style: AppText.custom(13, FontWeight.w500, color: AppColors.muted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
