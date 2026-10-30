import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/order_model.dart';

/// `/order-confirmation` (extra: OrderModel), spec C12.
class OrderConfirmationScreen extends StatelessWidget {
  final OrderModel order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Order number', formatOrderNumber(order.id)),
      ('Items', '${order.itemCount}'),
      ('Total', formatTaka(order.total)),
      ('Payment', order.paymentMethod.label),
      ('Deliver to', order.deliveryAddress),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    AppSpacing.l,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryTint,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 36,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      Semantics(
                        header: true,
                        child: Text('Order placed', style: AppText.headline),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        "We've received your order. You'll get updates as it moves.",
                        textAlign: TextAlign.center,
                        style: AppText.body.withColor(AppColors.muted),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.l,
                          vertical: 14,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: AppRadius.cardAll,
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < rows.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      rows[i].$1,
                                      style: AppText.meta.withColor(
                                        AppColors.muted,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      rows[i].$2,
                                      textAlign: TextAlign.end,
                                      style: AppText.meta.withWeight(
                                        i == 0
                                            ? FontWeight.w800
                                            : FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                child: Column(
                  children: [
                    AppButton.primary(
                      label: 'Track my order',
                      onPressed: () {
                        context.go('/home');
                        context.push('/tracking/${order.id}');
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),
                    AppButton.outline(
                      label: 'Continue shopping',
                      onPressed: () => context.go('/home'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
