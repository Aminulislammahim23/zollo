import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../products/presentation/providers/products_provider.dart';

/// Product photo for an order line: the snapshot saved with the order,
/// or else the current catalogue photo looked up by id.
class OrderThumbnail extends ConsumerWidget {
  const OrderThumbnail({
    super.key,
    required this.productId,
    this.imageUrl,
    this.size = 64,
  });

  final String productId;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url =
        imageUrl ?? ref.watch(productLookupProvider)[productId]?.imageUrl;
    return AppNetworkImage(
      url: url ?? '',
      width: size,
      height: size,
      borderRadius: AppRadius.tileAll,
    );
  }
}
