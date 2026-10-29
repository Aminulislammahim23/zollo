import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zollo/features/products/data/repositories/product_repository.dart';
import 'package:zollo/features/products/domain/models/product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProducts();
});

/// Loaded products by id, for thumbnails on screens that only store ids
/// (orders, wishlist). Empty until [productsProvider] has data.
final productLookupProvider = Provider<Map<String, Product>>((ref) {
  final products = ref.watch(productsProvider).value ?? const <Product>[];
  return {for (final p in products) p.id: p};
});
