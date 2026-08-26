import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_user.dart';
import '../data/firestore_profile_repository.dart';
import '../data/profile_setup_draft_store.dart';
import '../domain/profile_repository.dart';
import '../domain/profile_setup_draft.dart';

final profileSetupDraftStoreProvider = Provider<ProfileSetupDraftStore>(
  (ref) => SharedPreferencesProfileSetupDraftStore(),
);

final profileSetupControllerProvider =
    AsyncNotifierProvider<ProfileSetupController, ProfileSetupDraft>(
  ProfileSetupController.new,
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => FirestoreProfileRepository(),
);

enum ProfileSaveStatus { idle, saving, success, error }

class ProfileSetupSaveState {
  const ProfileSetupSaveState(this.status, {this.errorCode});
  const ProfileSetupSaveState.idle() : this(ProfileSaveStatus.idle);
  final ProfileSaveStatus status;
  final String? errorCode;
  bool get isSaving => status == ProfileSaveStatus.saving;
}

final profileSetupSaveControllerProvider =
    NotifierProvider<ProfileSetupSaveController, ProfileSetupSaveState>(
  ProfileSetupSaveController.new,
);

class ProfileSetupSaveController extends Notifier<ProfileSetupSaveState> {
  @override
  ProfileSetupSaveState build() => const ProfileSetupSaveState.idle();

  Future<bool> complete(AuthUser? user) async {
    if (state.isSaving) return false;
    if (user == null) {
      state = const ProfileSetupSaveState(ProfileSaveStatus.error,
          errorCode: 'saveFailed');
      return false;
    }
    final draft = ref.read(profileSetupControllerProvider).valueOrNull;
    if (draft == null) return false;
    state = const ProfileSetupSaveState(ProfileSaveStatus.saving);
    try {
      await ref
          .read(profileRepositoryProvider)
          .createOrUpdateProfile(user, draft);
      await ref.read(profileSetupDraftStoreProvider).clear();
      state = const ProfileSetupSaveState(ProfileSaveStatus.success);
      return true;
    } on ProfileFailure catch (error) {
      state =
          ProfileSetupSaveState(ProfileSaveStatus.error, errorCode: error.code);
      return false;
    }
  }
}

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
