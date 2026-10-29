import 'package:flutter/material.dart';

import '../../features/orders/domain/models/order_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class StatusText extends StatelessWidget {
  const StatusText(this.status, {super.key});

  final OrderStatus status;

  static String labelOf(OrderStatus status) => switch (status) {
    OrderStatus.pending => 'Pending',
    OrderStatus.confirmed => 'Confirmed',
    OrderStatus.processing => 'Processing',
    OrderStatus.shipped => 'Shipped',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Cancelled',
  };

  static Color colorOf(OrderStatus status) => switch (status) {
    OrderStatus.pending => AppColors.warning,
    OrderStatus.confirmed ||
    OrderStatus.processing ||
    OrderStatus.shipped => AppColors.primary,
    OrderStatus.delivered => AppColors.inkSoft,
    OrderStatus.cancelled => AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    return Text(
      labelOf(status),
      style: AppText.custom(13, FontWeight.w800, color: colorOf(status)),
    );
  }
}
