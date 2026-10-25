import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/review.dart';

class ReviewRepository {
  ReviewRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<ProductReview>> getReviews(
    String productId,
  ) async {
    final rows = await _supabase
        .from('product_reviews')
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false);

    return rows
        .map(
          (row) => ProductReview.fromMap(row),
        )
        .toList();
  }

  /// Verifies whether the logged-in user has completed an order containing this product.
  Future<bool> hasUserCompletedOrderForProduct(String productId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      // Check user's orders in the orders table
      final rows = await _supabase
          .from('orders')
          .select()
          .eq('user_id', user.id);

      for (final row in rows) {
        final status = (row['status'] as String?)?.toLowerCase();
        // Completed/delivered orders validate eligibility
        if (status == 'delivered' ||
            status == 'completed' ||
            status == 'confirmed' ||
            status == 'processing') {
          final items = row['items'] as List<dynamic>?;
          if (items != null) {
            for (final item in items) {
              if (item is Map && item['product_id'] == productId) {
                return true;
              }
            }
          }
        }
      }

      // Check order_items table if present
      final orderItems = await _supabase
          .from('order_items')
          .select('id, order_id, product_id, orders!inner(user_id, status)')
          .eq('product_id', productId)
          .eq('orders.user_id', user.id);

      if (orderItems.isNotEmpty) {
        return true;
      }
    } catch (_) {
      // Fallback for schema variations
    }

    return false;
  }

  Future<void> submitReview({
    required String productId,
    required int rating,
    String? comment,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be 1 to 5.');
    }

    // Business rule: Verify if the user has purchased the product
    final hasPurchased = await hasUserCompletedOrderForProduct(productId);
    if (!hasPurchased) {
      throw Exception(
        'Only verified buyers with an order can review this product.',
      );
    }

    final normalizedComment = comment?.trim();

    await _supabase.from('product_reviews').upsert(
      {
        'product_id': productId,
        'user_id': user.id,
        'rating': rating,
        'comment': normalizedComment == null || normalizedComment.isEmpty
            ? null
            : normalizedComment,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'product_id,user_id',
    );
  }
}
