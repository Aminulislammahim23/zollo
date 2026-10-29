import 'package:flutter/foundation.dart';

import 'models/product.dart';

enum ProductSort { popular, priceLowToHigh, priceHighToLow }

/// Client-side search, filter and sort over [productsProvider] data.
@immutable
class ProductFilter {
  const ProductFilter({
    this.query = '',
    this.sort = ProductSort.popular,
    this.minRating4 = false,
    this.categoryIds = const {},
    this.minPrice,
    this.maxPrice,
  });

  final String query;
  final ProductSort sort;
  final bool minRating4;
  final Set<String> categoryIds;
  final double? minPrice;
  final double? maxPrice;

  bool get hasFilters =>
      query.isNotEmpty ||
      sort != ProductSort.popular ||
      minRating4 ||
      categoryIds.isNotEmpty ||
      minPrice != null ||
      maxPrice != null;

  ProductFilter copyWith({
    String? query,
    ProductSort? sort,
    bool? minRating4,
    Set<String>? categoryIds,
    double? Function()? minPrice,
    double? Function()? maxPrice,
  }) {
    return ProductFilter(
      query: query ?? this.query,
      sort: sort ?? this.sort,
      minRating4: minRating4 ?? this.minRating4,
      categoryIds: categoryIds ?? this.categoryIds,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
    );
  }

  /// [categoryNames] maps category id → name so products that only carry the
  /// joined name (no `category_id`) still match.
  List<Product> apply(List<Product> products, {Map<String, String> categoryNames = const {}}) {
    final q = query.trim().toLowerCase();
    final wantedNames = {
      for (final id in categoryIds)
        if (categoryNames[id] != null) categoryNames[id]!.toLowerCase(),
    };

    final result = products.where((p) {
      if (q.isNotEmpty &&
          !p.title.toLowerCase().contains(q) &&
          !p.category.toLowerCase().contains(q)) {
        return false;
      }
      if (minRating4 && p.rating < 4) return false;
      if (categoryIds.isNotEmpty &&
          !categoryIds.contains(p.categoryId) &&
          !wantedNames.contains(p.category.toLowerCase())) {
        return false;
      }
      if (minPrice != null && p.price < minPrice!) return false;
      if (maxPrice != null && p.price > maxPrice!) return false;
      return true;
    }).toList();

    switch (sort) {
      case ProductSort.popular:
        result.sort((a, b) {
          final sold = b.soldCount.compareTo(a.soldCount);
          return sold != 0 ? sold : b.rating.compareTo(a.rating);
        });
      case ProductSort.priceLowToHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
      case ProductSort.priceHighToLow:
        result.sort((a, b) => b.price.compareTo(a.price));
    }
    return result;
  }
}
