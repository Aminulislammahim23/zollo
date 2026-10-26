class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final int stock;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.stock,
  });

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
    if (json['rating'] is num) {
      rating = (json['rating'] as num).toDouble();
    } else if (json['rating'] is Map) {
      rating = ((json['rating'] as Map)['rate'] as num?)?.toDouble() ?? 0.0;
    } else if (json['avg_rating'] is num) {
      rating = (json['avg_rating'] as num).toDouble();
    }

    final int stockVal = (json['stock_quantity'] ?? json['stock'] ?? json['quantity'] ?? 0) is num
        ? ((json['stock_quantity'] ?? json['stock'] ?? json['quantity'] ?? 0) as num).toInt()
        : 0;

    return Product(
      id: json['id'].toString(),
      title: (json['name'] ?? json['title'] ?? json['product_name'] ?? 'Untitled Product').toString(),
      description: (json['description'] ?? json['desc'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: (json['image_url'] ?? json['image'] ?? json['imageUrl'] ?? json['img_url'] ?? '').toString(),
      category: categoryName,
      rating: rating,
      stock: stockVal,
    );
  }
}
