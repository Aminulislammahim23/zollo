import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zollo/features/products/domain/models/product.dart';

class ProductRepository {
  ProductRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Product>> getProducts() async {
    List<dynamic> response;
    try {
      // Primary query: fetch products with active filter and joined categories
      response = await _client
          .from('products')
          .select('''
            *,
            categories (
              name
            )
          ''')
          .eq('is_active', true)
          .order('created_at', ascending: false);
    } catch (_) {
      try {
        // Fallback 1: query without is_active filter
        response = await _client.from('products').select('''
              *,
              categories (
                name
              )
            ''');
      } catch (_) {
        try {
          // Fallback 2: simple select without joins or filters
          response = await _client.from('products').select('*');
        } catch (e) {
          rethrow;
        }
      }
    }

    return response
        .map((row) => Product.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}
