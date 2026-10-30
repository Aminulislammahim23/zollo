import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../address/domain/address_model.dart';
import '../../address/presentation/providers/address_provider.dart';
import '../../auth/domain/providers/auth_provider.dart';
import '../../cart/domain/models/cart_item.dart';
import '../../cart/presentation/providers/cart_provider.dart';
import '../../orders/domain/models/payment_method.dart';
import '../../orders/domain/models/place_order_request.dart';
import '../../orders/domain/order_exception.dart';
import '../../orders/presentation/providers/order_provider.dart';

/// `/checkout`, spec C11.
class CheckoutScreen extends ConsumerStatefulWidget {
  /// Kept for the router contract; the screen always recomputes the
  /// subtotal from the cart so the total shown matches what is saved.
  final double subtotal;
  final double deliveryCharge;

  const CheckoutScreen({
    super.key,
    required this.subtotal,
    this.deliveryCharge = AppConstants.deliveryFee,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;
  Address? _selectedAddress;

  /// One key per checkout attempt: tapping "Place order" again after a
  /// timeout returns the same order instead of creating a second one.
  /// It is renewed only when the cart or address changes, or the order succeeds.
  String? _idempotencyKey;
  String? _keyFingerprint;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changeAddress() async {
    final selected = await context.push<Address>('/addresses?select=true');
    if (selected != null && mounted) {
      setState(() => _selectedAddress = selected);
    }
  }

  String _keyFor(Address address, List<CartItem> cartItems) {
    final fingerprint =
        '${address.id}|${cartItems.map((i) => '${i.product.id}x${i.quantity}').join(',')}';
    if (_idempotencyKey == null || _keyFingerprint != fingerprint) {
      _idempotencyKey = const Uuid().v4();
      _keyFingerprint = fingerprint;
    }
    return _idempotencyKey!;
  }

  Future<void> _submitOrder() async {
    final addressToUse =
        _selectedAddress ?? ref.read(defaultAddressProvider).value;
    if (addressToUse == null) {
      _showMessage('Please select or add a delivery address.');
      return;
    }

    final cartItems = ref.read(cartProvider).values.toList();
    if (cartItems.isEmpty) {
      _showMessage('Your cart is empty.');
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showMessage('Please log in to place your order.');
      return;
    }

    final request = PlaceOrderRequest(
      items: cartItems
          .map(
            (item) => PlaceOrderLine(
              productId: item.product.id,
              quantity: item.quantity,
              productName: item.product.title,
              unitPrice: item.product.price,
            ),
          )
          .toList(),
      addressId: addressToUse.id,
      paymentMethod: _paymentMethod,
      idempotencyKey: _keyFor(addressToUse, cartItems),
      shippingFee: widget.deliveryCharge,
    );

    try {
      final savedOrder = await ref
          .read(placeOrderProvider.notifier)
          .placeOrder(request);
      _idempotencyKey = null;
      if (!mounted) return;
      ref.read(cartProvider.notifier).clearCart();
      context.go('/order-confirmation', extra: savedOrder);
    } catch (error) {
      _showMessage(
        error is OrderException
            ? error.message
            : "Couldn't place your order. ${ErrorView.describe(error)}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final itemCount = ref.watch(cartItemCountProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final total = subtotal + widget.deliveryCharge;
    final isPlacingOrder = ref.watch(placeOrderProvider).isLoading;
    final defaultAddressAsync = ref.watch(defaultAddressProvider);
    final address = _selectedAddress ?? defaultAddressAsync.value;

    if (cart.isEmpty && !isPlacingOrder) {
      return Scaffold(
        appBar: const AppTopBar(title: 'Checkout', fallbackRoute: '/cart'),
        body: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Your cart is empty',
          message: 'Add something to your cart before checking out.',
          actionLabel: 'Start shopping',
          onAction: () => context.go('/home'),
        ),
      );
    }

    return Scaffold(
      appBar: const AppTopBar(title: 'Checkout', fallbackRoute: '/cart'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          _AddressCard(
            address: address,
            loading: defaultAddressAsync.isLoading && _selectedAddress == null,
            onChange: _changeAddress,
          ),
          const SizedBox(height: AppSpacing.cardGap),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Package 1 · $itemCount ${itemCount == 1 ? 'item' : 'items'}',
                  style: AppText.label,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      size: AppSpacing.iconSmall,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Text(
                        'Standard delivery · arrives in 2–4 days',
                        style: AppText.bodySmall.withColor(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Payment method', style: AppText.cardTitle),
                const SizedBox(height: AppSpacing.s),
                RadioGroup<PaymentMethod>(
                  groupValue: _paymentMethod,
                  onChanged: (_) {},
                  child: const Column(
                    children: [
                      _PaymentRow(
                        code: 'COD',
                        title: 'Cash on delivery',
                        note: 'Pay the rider when it arrives',
                        method: PaymentMethod.cashOnDelivery,
                      ),
                      _PaymentRow(
                        code: 'bK',
                        title: 'bKash',
                        note: 'Pay with your bKash account',
                      ),
                      _PaymentRow(
                        code: 'Ng',
                        title: 'Nagad',
                        note: 'Pay with your Nagad account',
                      ),
                      _PaymentRow(
                        code: 'Card',
                        title: 'Credit or debit card',
                        note: 'Visa, Mastercard, Amex',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          InfoCard(
            child: Column(
              children: [
                _SummaryRow(label: 'Items total', value: formatTaka(subtotal)),
                const SizedBox(height: AppSpacing.s),
                _SummaryRow(
                  label: 'Delivery',
                  value: formatTaka(widget.deliveryCharge),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.m,
          AppSpacing.l,
          20,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pay in cash on delivery',
                      style: AppText.caption.withColor(AppColors.muted),
                    ),
                    Text(
                      formatTaka(total),
                      style: AppText.totalPrice.withColor(AppColors.primary),
                    ),
                  ],
                ),
              ),
              AppButton.primary(
                label: 'Place order',
                fullWidth: false,
                loading: isPlacingOrder,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                onPressed: _submitOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.loading,
    required this.onChange,
  });

  final Address? address;
  final bool loading;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    if (loading) return const ShimmerBox(height: 88, radius: AppRadius.card);

    if (address == null) {
      return InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: AppSpacing.iconBar,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    'Add a delivery address',
                    style: AppText.bodyStrong,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            AppButton.outline(
              label: 'Add address',
              icon: Icons.add,
              size: AppButtonSize.small,
              onPressed: () => context.push('/add-address'),
            ),
          ],
        ),
      );
    }

    final a = address!;
    return InfoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: AppSpacing.iconBar,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${a.fullName} · ${a.phone}', style: AppText.bodyStrong),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  a.displayAddress,
                  style: AppText.meta.copyWith(
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: const Text('Change')),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.code,
    required this.title,
    required this.note,
    this.method,
  });

  final String code;
  final String title;
  final String note;

  /// Null = not available yet (shown disabled with a "Coming soon" tag).
  final PaymentMethod? method;

  @override
  Widget build(BuildContext context) {
    final enabled = method != null;
    return Semantics(
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: AppRadius.tileAll,
                ),
                child: Text(code, style: AppText.tag),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.bodyStrong),
                    Text(
                      note,
                      style: AppText.caption.withColor(AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Radio<PaymentMethod>(value: method!)
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: 3,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: AppRadius.badgeAll,
                  ),
                  child: Text(
                    'Coming soon',
                    style: AppText.microStrong.withColor(AppColors.muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppText.meta.withColor(AppColors.muted)),
        ),
        Text(value, style: AppText.label),
      ],
    );
  }
}
