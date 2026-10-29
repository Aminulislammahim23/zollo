// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../cart/presentation/providers/cart_provider.dart';
import '../../orders/domain/models/order_model.dart';
import '../../orders/presentation/providers/order_provider.dart';
import '../../address/presentation/providers/address_provider.dart';
import '../../address/domain/address_model.dart';
import '../models/checkout_order.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final double subtotal;
  final double deliveryCharge;

  const CheckoutScreen({
    super.key,
    required this.subtotal,
    this.deliveryCharge = 120,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;
  Address? _selectedAddress;

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> submitOrder() async {
    final defaultAddr = ref.read(defaultAddressProvider).value;
    final addressToUse = _selectedAddress ?? defaultAddr;

    if (addressToUse == null) {
      showMessage('Please select or add a delivery address.');
      return;
    }

    final cartItems = ref.read(cartProvider).values.toList();
    if (cartItems.isEmpty) {
      showMessage('Your cart is empty.');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      showMessage('Please sign in to place your order.');
      return;
    }

    // Address snapshot string so history isn't altered by future address edits
    final addressSnapshot =
        '${addressToUse.fullName} · ${addressToUse.phone}\n${addressToUse.formattedAddress}';

    final order = OrderModel(
      id: const Uuid().v4(),
      userId: user.id,
      items: cartItems.map((item) {
        return OrderItem(
          productId: item.product.id,
          productName: item.product.title,
          price: item.product.price,
          quantity: item.quantity,
        );
      }).toList(),
      shippingAddress: addressSnapshot,
      shippingFee: widget.deliveryCharge,
      status: OrderStatus.pending,
      createdAt: DateTime.now().toUtc(),
    );

    try {
      final savedOrder = await ref
          .read(placeOrderProvider.notifier)
          .placeOrder(order);

      if (!mounted) return;

      ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;

      context.go('/order-confirmation', extra: savedOrder);
    } catch (error) {
      if (!mounted) return;
      final errorMessage = error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : error.toString();
      showMessage('Order error: $errorMessage');
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.subtotal + widget.deliveryCharge - 100;
    final isPlacingOrder = ref.watch(placeOrderProvider).isLoading;
    final defaultAddressAsync = ref.watch(defaultAddressProvider);
    final currentAddress = _selectedAddress ?? defaultAddressAsync.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.black87,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // 1. Delivery Address Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF006B54),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                currentAddress != null
                                    ? '${currentAddress.fullName} · ${currentAddress.phone}'
                                    : 'No delivery address selected',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final selected = await context.push<Address>(
                                    '/addresses?select=true',
                                  );
                                  if (selected != null) {
                                    setState(() {
                                      _selectedAddress = selected;
                                    });
                                  }
                                },
                                child: const Text(
                                  'Change',
                                  style: TextStyle(
                                    color: Color(0xFF006B54),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentAddress != null
                                ? currentAddress.formattedAddress
                                : 'Tap "Change" to select or add a delivery address.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Package / Delivery Method Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Package 1 · [Seller store A]',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Items',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1),
                    ),
                    const Row(
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 18,
                          color: Color(0xFF006B54),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Standard delivery · arrives in 2–4 days',
                          style: TextStyle(
                            color: Color(0xFF006B54),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Payment Method Card
              const Text(
                'Payment method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _paymentOption(
                      code: 'bK',
                      title: 'bKash',
                      subtitle: 'Pay with your bKash account',
                      method: PaymentMethod.online,
                    ),
                    const Divider(height: 1, indent: 60),
                    _paymentOption(
                      code: 'Ng',
                      title: 'Nagad',
                      subtitle: 'Pay with your Nagad account',
                      method: PaymentMethod.online,
                    ),
                    const Divider(height: 1, indent: 60),
                    _paymentOption(
                      code: 'Card',
                      title: 'Credit or debit card',
                      subtitle: 'Visa, Mastercard, Amex via SSLCommerz',
                      method: PaymentMethod.online,
                    ),
                    const Divider(height: 1, indent: 60),
                    _paymentOption(
                      code: 'COD',
                      title: 'Cash on delivery',
                      subtitle: 'Pay the rider when it arrives',
                      method: PaymentMethod.cashOnDelivery,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Order Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _summaryRow('Items total', widget.subtotal),
                    const SizedBox(height: 8),
                    _summaryRow('Delivery', widget.deliveryCharge),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Voucher',
                            style: TextStyle(color: Colors.black87)),
                        const Text(
                          '-৳100',
                          style: TextStyle(
                            color: Color(0xFF006B54),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bottom Sticky Place Order Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total to pay now',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '৳${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF006B54),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 50,
                      width: 180,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF006B54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isPlacingOrder ? null : submitOrder,
                        child: isPlacingOrder
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Place order',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption({
    required String code,
    required String title,
    required String subtitle,
    required PaymentMethod method,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod = method;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                code,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: _paymentMethod,
              activeColor: const Color(0xFF006B54),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _paymentMethod = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black87)),
        Text(
          '৳${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
