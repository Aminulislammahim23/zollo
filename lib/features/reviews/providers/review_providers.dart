import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/domain/providers/auth_provider.dart';
import '../data/review_repository.dart';
import '../domain/review.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(Supabase.instance.client);
});

final productReviewsProvider =
    FutureProvider.family<List<ProductReview>, String>((ref, productId) {
      return ref.watch(reviewRepositoryProvider).getReviews(productId);
    });

final canUserReviewProvider = FutureProvider.family<bool, String>((
  ref,
  productId,
) {
  if (ref.watch(currentUserProvider.select((u) => u?.id)) == null) {
    return Future.value(false);
  }
  return ref
      .watch(reviewRepositoryProvider)
      .hasUserCompletedOrderForProduct(productId);
});
