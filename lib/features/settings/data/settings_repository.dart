import 'package:shared_preferences/shared_preferences.dart';

enum NotificationPref {
  orderUpdates('Order updates', 'Packing, shipping and delivery'),
  messages('Messages', 'Replies from sellers'),
  priceDrops('Price drops', 'Items in your wishlist get cheaper'),
  offers('Offers and campaigns', 'Sales, vouchers and new arrivals');

  const NotificationPref(this.title, this.note);
  final String title;
  final String note;

  String get key => 'notify_$name';
}

/// Device-level preferences stored in SharedPreferences.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String localeKey = 'app_locale';

  /// `en` or `bn`.
  String get locale => _prefs.getString(localeKey) ?? 'en';

  Future<void> setLocale(String code) => _prefs.setString(localeKey, code);

  bool isEnabled(NotificationPref pref) => _prefs.getBool(pref.key) ?? true;

  Future<void> setEnabled(NotificationPref pref, bool value) =>
      _prefs.setBool(pref.key, value);
}
