
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/wishlist_repository.dart';

final wishlistRepositoryProvider =
Provider<WishlistRepository>((ref) {
  return WishlistRepository(
    Supabase.instance.client,
  );
});

final wishlistProvider =
AsyncNotifierProvider<WishlistNotifier, Set<String>>(
  WishlistNotifier.new,
);

class WishlistNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    return ref.read(wishlistRepositoryProvider).getProductIds();
  }

  Future<void> toggle(String productId) async {
    final repository = ref.read(wishlistRepositoryProvider);
    final previous = state.value ?? <String>{};

    final shouldRemove = previous.contains(productId);
    final updated = Set<String>.from(previous);

    if (shouldRemove) {
      updated.remove(productId);
    } else {
      updated.add(productId);
    }

    // Optimistic UI update.
    state = AsyncData(updated);

    try {
      if (shouldRemove) {
        await repository.remove(productId);
      } else {
        await repository.add(productId);
      }
    } catch (_) {
      // Roll back if the database operation fails.
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => ref.read(wishlistRepositoryProvider).getProductIds(),
    );
  }
}
