import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_setup_draft_store.dart';
import '../domain/profile_setup_draft.dart';

final profileSetupDraftStoreProvider = Provider<ProfileSetupDraftStore>(
  (ref) => SharedPreferencesProfileSetupDraftStore(),
);

final profileSetupControllerProvider =
    AsyncNotifierProvider<ProfileSetupController, ProfileSetupDraft>(
  ProfileSetupController.new,
);

class ProfileSetupController extends AsyncNotifier<ProfileSetupDraft> {
  @override
  Future<ProfileSetupDraft> build() =>
      ref.read(profileSetupDraftStoreProvider).load();

  Future<void> toggleChoice(ProfileQuestion question, String choiceId,
      {required int maximum}) async {
    final current = state.valueOrNull ?? const ProfileSetupDraft();
    final choices = {...current.choicesFor(question)};
    if (!choices.add(choiceId)) choices.remove(choiceId);
    if (choices.length > maximum) return;
    await _save(current.copyWith(
      selections: {...current.selections, question: choices},
    ));
  }

  Future<void> setPersonalAnswer(String answer) => _save(
        (state.valueOrNull ?? const ProfileSetupDraft())
            .copyWith(personalAnswer: answer),
      );

  Future<void> _save(ProfileSetupDraft next) async {
    state = AsyncData(next);
    await ref.read(profileSetupDraftStoreProvider).save(next);
  }
}
