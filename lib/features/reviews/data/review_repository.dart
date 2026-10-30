import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/review.dart';

class ReviewRepository {
  ReviewRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<ProductReview>> getReviews(String productId) async {
    final rows = await _supabase
        .from('product_reviews')
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false);

    return rows.map((row) => ProductReview.fromMap(row)).toList();
  }

  /// Whether the signed-in user has a delivered order containing this
  /// product, the same rule the product_reviews insert policy enforces.
  Future<bool> hasDeliveredOrderForProduct(String productId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final rows = await _supabase
        .from('order_items')
        .select('id, orders!inner(user_id, status)')
        .eq('product_id', productId)
        .eq('orders.user_id', user.id)
        .eq('orders.status', 'delivered')
        .limit(1);
    return rows.isNotEmpty;
  }

  /// Creates or updates the user's review. Row Level Security rejects it
  /// unless a delivered order contains the product.
  Future<void> submitReview({
    required String productId,
    required int rating,
    String? comment,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Please log in first.');
    }

    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be 1 to 5.');
    }

    final normalizedComment = comment?.trim();

    try {
      await _supabase.from('product_reviews').upsert({
        'product_id': productId,
        'user_id': user.id,
        'rating': rating,
        'comment': normalizedComment == null || normalizedComment.isEmpty
            ? null
            : normalizedComment,
      }, onConflict: 'product_id,user_id');
    } on PostgrestException catch (e) {
      if (isRlsViolation(e)) throw const ReviewNotAllowedException();
      rethrow;
    }
  }

  /// 42501 = insufficient_privilege, raised when a policy rejects the row.
  static bool isRlsViolation(PostgrestException e) =>
      e.code == '42501' || e.message.contains('row-level security');
}

/// The reviewer has no delivered order containing the product.
class ReviewNotAllowedException implements Exception {
  const ReviewNotAllowedException();

  static const message = 'You can review this after it is delivered.';

  @override
  String toString() => message;
}
