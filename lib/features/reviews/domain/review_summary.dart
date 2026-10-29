import 'review.dart';

class ReviewSummary {
  const ReviewSummary({
    required this.average,
    required this.count,
    required this.distribution,
  });

  factory ReviewSummary.from(List<ProductReview> reviews) {
    final distribution = List<int>.filled(5, 0);
    var total = 0;
    for (final r in reviews) {
      final stars = r.rating.clamp(1, 5);
      distribution[stars - 1]++;
      total += stars;
    }
    return ReviewSummary(
      average: reviews.isEmpty ? 0 : total / reviews.length,
      count: reviews.length,
      distribution: distribution,
    );
  }

  final double average;
  final int count;

  /// Index 0 = 1★ … index 4 = 5★.
  final List<int> distribution;

  int countFor(int stars) => distribution[stars - 1];
}
