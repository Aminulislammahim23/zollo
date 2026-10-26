import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zollo/features/onboarding/data/onboarding_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingRepository Tests', () {
    late SharedPreferences prefs;
    late OnboardingRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = OnboardingRepository(prefs);
    });

    test('isOnboardingCompleted returns false by default', () async {
      final isCompleted = await repository.isOnboardingCompleted();
      expect(isCompleted, false);
    });

    test('setOnboardingCompleted updates preference to true', () async {
      await repository.setOnboardingCompleted();
      final isCompleted = await repository.isOnboardingCompleted();
      expect(isCompleted, true);
    });

    test('clearOnboarding resets preference status', () async {
      await repository.setOnboardingCompleted();
      expect(await repository.isOnboardingCompleted(), true);

      await repository.clearOnboarding();
      expect(await repository.isOnboardingCompleted(), false);
    });
  });
}
