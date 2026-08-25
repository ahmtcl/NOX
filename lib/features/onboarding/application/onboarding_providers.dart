import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_completion_store.dart';

final onboardingCompletionStoreProvider = Provider<OnboardingCompletionStore>(
  (ref) => SharedPreferencesOnboardingCompletionStore(),
);
