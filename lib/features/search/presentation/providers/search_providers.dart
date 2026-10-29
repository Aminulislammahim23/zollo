import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../products/domain/models/product.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../data/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return LocalSearchRepository(ref.watch(sharedPreferencesProvider));
});

final recentSearchesProvider = NotifierProvider<RecentSearchesController, List<String>>(
  RecentSearchesController.new,
);

class RecentSearchesController extends Notifier<List<String>> {
  @override
  List<String> build() => ref.read(searchRepositoryProvider).recentSearches();

  Future<void> add(String query) async {
    state = await ref.read(searchRepositoryProvider).addRecent(query);
  }

  Future<void> clear() async {
    await ref.read(searchRepositoryProvider).clearRecent();
    state = const [];
  }
}

final trendingSearchesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(searchRepositoryProvider).trending();
});

/// Products whose name contains [query] (case-insensitive), best matches first.
final searchSuggestionsProvider = Provider.family<List<Product>, String>((ref, query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final products = ref.watch(productsProvider).value ?? const <Product>[];
  final matches = products.where((p) => p.title.toLowerCase().contains(q)).toList()
    ..sort((a, b) {
      final aStarts = a.title.toLowerCase().startsWith(q) ? 0 : 1;
      final bStarts = b.title.toLowerCase().startsWith(q) ? 0 : 1;
      return aStarts != bStarts ? aStarts - bStarts : a.title.compareTo(b.title);
    });
  return matches.take(10).toList();
});
