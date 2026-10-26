import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  final SharedPreferences _prefs;

  static const String onboardingKey = 'onboarding_completed';

  OnboardingRepository(this._prefs);

  /// Checks if onboarding has been completed.
  Future<bool> isOnboardingCompleted() async {
    return _prefs.getBool(onboardingKey) ?? false;
  }

  /// Sets onboarding as completed.
  Future<void> setOnboardingCompleted() async {
    await _prefs.setBool(onboardingKey, true);
  }

  /// Clears onboarding completion status.
  Future<void> clearOnboarding() async {
    await _prefs.remove(onboardingKey);
  }
}
