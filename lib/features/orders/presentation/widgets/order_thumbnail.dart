import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../products/presentation/providers/products_provider.dart';

/// Product photo for an order line, looked up from the catalogue by id.
class OrderThumbnail extends ConsumerWidget {
  const OrderThumbnail({super.key, required this.productId, this.size = 64});

  final String productId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productLookupProvider)[productId];
    return AppNetworkImage(
      url: product?.imageUrl ?? '',
      width: size,
      height: size,
      borderRadius: AppRadius.tileAll,
    );
  }
}
