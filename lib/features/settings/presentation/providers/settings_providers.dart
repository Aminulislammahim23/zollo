import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(sharedPreferencesProvider));
});

/// Chosen language code. Only stored for now; translations come later.
final localeProvider = NotifierProvider<LocaleController, String>(
  LocaleController.new,
);

class LocaleController extends Notifier<String> {
  @override
  String build() => ref.read(settingsRepositoryProvider).locale;

  Future<void> set(String code) async {
    state = code;
    await ref.read(settingsRepositoryProvider).setLocale(code);
  }
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsController, Map<NotificationPref, bool>>(
      NotificationPrefsController.new,
    );

class NotificationPrefsController
    extends Notifier<Map<NotificationPref, bool>> {
  @override
  Map<NotificationPref, bool> build() {
    final repo = ref.read(settingsRepositoryProvider);
    return {for (final p in NotificationPref.values) p: repo.isEnabled(p)};
  }

  Future<void> set(NotificationPref pref, bool value) async {
    state = {...state, pref: value};
    await ref.read(settingsRepositoryProvider).setEnabled(pref, value);
  }
}
