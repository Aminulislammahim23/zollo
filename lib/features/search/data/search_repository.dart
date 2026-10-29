import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SearchRepository {
  /// Newest first, at most [maxRecent].
  List<String> recentSearches();

  Future<List<String>> addRecent(String query);

  Future<void> clearRecent();

  Future<List<String>> trending();
}

/// Recent searches live in SharedPreferences on the device.
class LocalSearchRepository implements SearchRepository {
  LocalSearchRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String recentKey = 'recent_searches';
  static const int maxRecent = 8;

  // TODO(backend): replace with Supabase implementation (top queries of the week).
  static const List<String> _trending = [
    'Wireless earbuds',
    'Smart watch',
    'Eid panjabi',
    'Air fryer',
    'Power bank',
    'Running shoes',
    'Bluetooth speaker',
    'Mechanical keyboard',
  ];

  @override
  List<String> recentSearches() => _prefs.getStringList(recentKey) ?? const [];

  @override
  Future<List<String>> addRecent(String query) async {
    final q = query.trim();
    if (q.isEmpty) return recentSearches();
    final updated = [
      q,
      ...recentSearches().where((r) => r.toLowerCase() != q.toLowerCase()),
    ].take(maxRecent).toList();
    await _prefs.setStringList(recentKey, updated);
    return updated;
  }

  @override
  Future<void> clearRecent() => _prefs.remove(recentKey);

  @override
  Future<List<String>> trending() async => _trending;
}
