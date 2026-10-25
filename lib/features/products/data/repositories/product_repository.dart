import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zollo/features/products/domain/models/product.dart';

class ProductRepository {
  ProductRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Product>> getProducts() async {
    final response = await _client
        .from('products')
        .select('''
          id,
          name,
          description,
          image_url,
          price,
          stock_quantity,
          categories (
            name
          )
        ''')
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) {
          final json = Map<String, dynamic>.from(row);
          final categoryData = json['categories'];

          final categoryName = categoryData is Map
              ? categoryData['name'] as String?
              : null;

          return Product(
            id: json['id'].toString(),
            title: json['name'] as String,
            description: json['description'] as String? ?? '',
            imageUrl: json['image_url'] as String? ?? '',
            price: (json['price'] as num).toDouble(),
            rating: 0.0,
            category: categoryName ?? 'Uncategorized',
            stock: (json['stock_quantity'] as num).toInt(),
          );
        })
        .toList();
  }
}
