
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/wishlist_provider.dart';

class WishlistButton extends ConsumerWidget {
  const WishlistButton({
    super.key,
    required this.productId,
  });

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final isFavorite =
        wishlist.value?.contains(productId) ?? false;

    return IconButton(
      tooltip: isFavorite
          ? 'Remove from wishlist'
          : 'Add to wishlist',
      onPressed: wishlist.isLoading
          ? null
          : () async {
        try {
          await ref
              .read(wishlistProvider.notifier)
              .toggle(productId);
        } catch (error) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Wishlist update failed: $error'),
            ),
          );
        }
      },
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : null,
      ),
    );
  }
}
