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
    return Product(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      rating:
          ((json['rating'] as Map<String, dynamic>?)?['rate'] as num?)
              ?.toDouble() ??
          0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }
}
