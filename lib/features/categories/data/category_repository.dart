import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/category.dart';

class CategoryRepository {
  CategoryRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Active categories, ordered by name.
  Future<List<Category>> getCategories() async {
    final rows = await _client
        .from('categories')
        .select('id, name, image_url')
        .eq('is_active', true)
        .order('name');

    return rows
        .map((row) => Category.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}
