class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final int stock;

  /// `categories.id`, empty when the product has no category.
  final String categoryId;

  /// Price before discount, when the backend provides one.
  final double? originalPrice;
  final int soldCount;
  final int ratingCount;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.stock,
    this.categoryId = '',
    this.originalPrice,
    this.soldCount = 0,
    this.ratingCount = 0,
  });

  bool get inStock => stock > 0;

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  /// Whole-number discount percentage, e.g. `23` for -23 %.
  int get discountPercent => hasDiscount
      ? (((originalPrice! - price) / originalPrice!) * 100).round()
      : 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    String categoryName = 'General';
    if (json['categories'] is Map) {
      categoryName = json['categories']['name'] as String? ?? 'General';
    } else if (json['category'] != null) {
      categoryName = json['category'].toString();
    } else if (json['category_name'] != null) {
      categoryName = json['category_name'].toString();
    }

    double rating = 0.0;
    int ratingCount = 0;
    if (json['rating'] is num) {
      rating = (json['rating'] as num).toDouble();
    } else if (json['rating'] is Map) {
      final map = json['rating'] as Map;
      rating = (map['rate'] as num?)?.toDouble() ?? 0.0;
      ratingCount = (map['count'] as num?)?.toInt() ?? 0;
    } else if (json['avg_rating'] is num) {
      rating = (json['avg_rating'] as num).toDouble();
    }
    final rawRatingCount = json['rating_count'] ?? json['review_count'];
    if (rawRatingCount is num) ratingCount = rawRatingCount.toInt();

    final int stockVal =
        (json['stock_quantity'] ?? json['stock'] ?? json['quantity'] ?? 0)
            is num
        ? ((json['stock_quantity'] ?? json['stock'] ?? json['quantity'] ?? 0)
                  as num)
              .toInt()
        : 0;

    final rawOriginal =
        json['original_price'] ??
        json['compare_at_price'] ??
        json['old_price'] ??
        json['mrp'];
    final rawSold = json['sold_count'] ?? json['sold'];

    return Product(
      id: json['id'].toString(),
      title:
          (json['name'] ??
                  json['title'] ??
                  json['product_name'] ??
                  'Untitled Product')
              .toString(),
      description: (json['description'] ?? json['desc'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl:
          (json['image_url'] ??
                  json['image'] ??
                  json['imageUrl'] ??
                  json['img_url'] ??
                  '')
              .toString(),
      category: categoryName,
      rating: rating,
      stock: stockVal,
      categoryId: json['category_id']?.toString() ?? '',
      originalPrice: rawOriginal is num ? rawOriginal.toDouble() : null,
      soldCount: rawSold is num ? rawSold.toInt() : 0,
      ratingCount: ratingCount,
    );
  }
}
