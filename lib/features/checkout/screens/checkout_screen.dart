import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../cart/presentation/providers/cart_provider.dart';
import '../../orders/domain/models/order_model.dart';
import '../../orders/presentation/providers/order_provider.dart';
import '../../orders/presentation/screens/order_confirmation_screen.dart';
import '../models/checkout_order.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final double subtotal;
  final double deliveryCharge;

  const CheckoutScreen({
    super.key,
    required this.subtotal,
    this.deliveryCharge = 60,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final shippingAddress = _addressController.text;
    if (shippingAddress.trim().isEmpty) {
      showMessage('Please enter a shipping address.');
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
      shippingAddress: shippingAddress.trim(),
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

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(
            order: savedOrder,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      showMessage('Order could not be placed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.subtotal + widget.deliveryCharge;
    final isPlacingOrder = ref.watch(placeOrderProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Delivery Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final phone = value?.trim() ?? '';

                  if (!RegExp(r'^(?:\+?8801|01)\d{9}$').hasMatch(phone)) {
                    return 'Enter a valid Bangladesh phone number';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Full delivery address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 8) {
                    return 'Enter a complete address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              RadioListTile<PaymentMethod>(
                title: const Text('Cash on Delivery'),
                value: PaymentMethod.cashOnDelivery,
                groupValue: _paymentMethod,
                onChanged: isPlacingOrder
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _paymentMethod = value;
                          });
                        }
                      },
              ),

              RadioListTile<PaymentMethod>(
                title: const Text('Online Payment'),
                subtitle: const Text('Gateway integration required'),
                value: PaymentMethod.online,
                groupValue: _paymentMethod,
                onChanged: isPlacingOrder
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _paymentMethod = value;
                          });
                        }
                      },
              ),

              const Divider(height: 32),

              _summaryRow('Subtotal', widget.subtotal),
              _summaryRow('Delivery charge', widget.deliveryCharge),
              const Divider(),

              _summaryRow('Total', total, bold: true),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: isPlacingOrder ? null : submitOrder,
                child: isPlacingOrder
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool bold = false}) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('৳${amount.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
