class ProductReview {
  final String id;
  final String productId;
  final String userId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  factory ProductReview.fromMap(Map<String, dynamic> map) {
    return ProductReview(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      userId: map['user_id'] as String,
      rating: map['rating'] as int,
      comment: map['comment'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'product_id': productId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
    };
  }
}
