import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/domain/models/product.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../data/category_repository.dart';
import '../../domain/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

/// Products in [category], matched by `category_id`, falling back to the
/// joined category name for rows that only carry the name.
List<Product> productsInCategory(List<Product> products, Category category) {
  return products
      .where((p) =>
          (p.categoryId.isNotEmpty && p.categoryId == category.id) ||
          (p.categoryId.isEmpty && p.category.toLowerCase() == category.name.toLowerCase()))
      .toList();
}

final productsByCategoryProvider =
    FutureProvider.family<List<Product>, Category>((ref, category) async {
  final products = await ref.watch(productsProvider.future);
  return productsInCategory(products, category);
});
