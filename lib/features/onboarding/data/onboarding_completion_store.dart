import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OnboardingCompletionStore {
  Future<bool> isCompleted();
  Future<void> markCompleted();
}

class SharedPreferencesOnboardingCompletionStore
    implements OnboardingCompletionStore {
  static const _key = 'onboarding_completed';

  @override
  Future<bool> isCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_key) ?? false;
  }

  @override
  Future<void> markCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key, true);
  }
}
