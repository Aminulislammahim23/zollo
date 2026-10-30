import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zollo/features/products/domain/models/product.dart';

class ProductRepository {
  ProductRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Active products, newest first, with their category name.
  /// `*` includes compare_at_price, rating and rating_count; price and
  /// stock_quantity are kept in sync with the variants by the database.
  Future<List<Product>> getProducts() async {
    final rows = await _client
        .from('products')
        .select('*, categories(name)')
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return rows.map(Product.fromJson).toList();
  }
}
