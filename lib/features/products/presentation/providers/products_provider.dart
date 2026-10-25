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
