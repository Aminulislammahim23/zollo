import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistRepository {
  WishlistRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('Please sign in to use wishlist.');
    }

    return user.id;
  }

  Future<Set<String>> getProductIds() async {
    final response = await _client
        .from('wishlist')
        .select('product_id')
        .eq('user_id', _userId);

    return response.map<String>((row) => row['product_id'] as String).toSet();
  }

  Future<void> add(String productId) async {
    await _client
        .from('wishlist')
        .upsert(
          {'user_id': _userId, 'product_id': productId},
          onConflict: 'user_id,product_id',
          ignoreDuplicates: true,
        );
  }

  Future<void> remove(String productId) async {
    await _client
        .from('wishlist')
        .delete()
        .eq('user_id', _userId)
        .eq('product_id', productId);
  }
}
