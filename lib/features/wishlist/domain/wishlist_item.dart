class WishlistItem {
  final String userId;
  final String productId;
  final DateTime createdAt;

  const WishlistItem({
    required this.userId,
    required this.productId,
    required this.createdAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'product_id': productId,
    'created_at': createdAt.toIso8601String(),
  };
}
