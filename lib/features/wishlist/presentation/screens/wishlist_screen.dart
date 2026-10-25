
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
      ),
      body: wishlist.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load wishlist.'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref
                    .read(wishlistProvider.notifier)
                    .reload(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (productIds) {
          if (productIds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 56,
                  ),
                  SizedBox(height: 12),
                  Text('Your wishlist is empty'),
                  Text('Save products you love here.'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: productIds.length,
            itemBuilder: (context, index) {
              final productId = productIds
                  .elementAt(index);

              return ListTile(
                leading: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                ),
                title: Text('Product $productId'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove from wishlist',
                  onPressed: () async {
                    try {
                      await ref
                          .read(wishlistProvider.notifier)
                          .toggle(productId);
                    } catch (_) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not remove product.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
