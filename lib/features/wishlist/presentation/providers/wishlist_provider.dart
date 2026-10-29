import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(Supabase.instance.client);
});

final wishlistProvider = AsyncNotifierProvider<WishlistNotifier, Set<String>>(
  WishlistNotifier.new,
);

class WishlistNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    // Guests have an empty wishlist; it reloads when the user logs in or out.
    final userId = ref.watch(currentUserProvider.select((u) => u?.id));
    if (userId == null) return <String>{};
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
