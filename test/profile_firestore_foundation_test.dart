import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox/features/auth/domain/auth_user.dart';
import 'package:nox/features/profile/application/profile_setup_controller.dart';
import 'package:nox/features/profile/data/profile_setup_draft_store.dart';
import 'package:nox/features/profile/domain/profile_repository.dart';
import 'package:nox/features/profile/domain/profile_setup_draft.dart';
import 'package:nox/features/profile/domain/user_profile.dart';

void main() {
  const user =
      AuthUser(id: 'user-1', email: 'nox@example.com', emailVerified: true);
  const draft = ProfileSetupDraft(selections: {
    ProfileQuestion.personality: {'curious', 'kind', 'bold'}
  }, personalAnswer: 'Hello NOX');

  group('Profile models', () {
    test('serializes setup answers with stable Firestore keys', () {
      final profile = UserProfile.fromSetupDraft(user.id, draft);
      final data = profile.toFirestore();
      expect(data['uid'], user.id);
      expect(data['personalityTraits'], ['bold', 'curious', 'kind']);
      expect(data['personalAnswer'], 'Hello NOX');
      expect(
          UserProfile.fromFirestore(data.cast<String, dynamic>()).city, isNull);
    });

    test('preferences omit unavailable optional values', () {
      final data = UserPreferences(uid: user.id).toFirestore();
      expect(data, {'uid': user.id});
      expect(
          UserPreferences.fromFirestore(data.cast<String, dynamic>())
              .preferredGender,
          isNull);
    });
  });

  group('Profile save controller', () {
    test('success writes once and clears the local draft', () async {
      final store = _FakeStore(draft);
      final repository = _FakeRepository();
      final container = _container(store, repository);
      addTearDown(container.dispose);
      await container.read(profileSetupControllerProvider.future);
      expect(
          await container
              .read(profileSetupSaveControllerProvider.notifier)
              .complete(user),
          isTrue);
      expect(repository.saveCalls, 1);
      expect(store.cleared, isTrue);
      expect(container.read(profileSetupSaveControllerProvider).status,
          ProfileSaveStatus.success);
    });

    test('failure preserves draft and exposes a retryable error', () async {
      final store = _FakeStore(draft);
      final repository = _FakeRepository(fail: true);
      final container = _container(store, repository);
      addTearDown(container.dispose);
      await container.read(profileSetupControllerProvider.future);
      expect(
          await container
              .read(profileSetupSaveControllerProvider.notifier)
              .complete(user),
          isFalse);
      expect(store.cleared, isFalse);
      expect(store.value.personalAnswer, 'Hello NOX');
      expect(container.read(profileSetupSaveControllerProvider).errorCode,
          'networkError');
    });
  });
}

ProviderContainer _container(_FakeStore store, _FakeRepository repository) =>
    ProviderContainer(overrides: [
      profileSetupDraftStoreProvider.overrideWithValue(store),
      profileRepositoryProvider.overrideWithValue(repository)
    ]);

class _FakeStore implements ProfileSetupDraftStore {
  _FakeStore(this.value);
  ProfileSetupDraft value;
  var cleared = false;
  @override
  Future<void> clear() async {
    cleared = true;
    value = const ProfileSetupDraft();
  }

  @override
  Future<ProfileSetupDraft> load() async => value;
  @override
  Future<void> save(ProfileSetupDraft draft) async => value = draft;
}

class _FakeRepository implements ProfileRepository {
  _FakeRepository({this.fail = false});
  final bool fail;
  var saveCalls = 0;
  @override
  Future<void> createOrUpdateProfile(
      AuthUser user, ProfileSetupDraft draft) async {
    saveCalls++;
    if (fail) throw const ProfileFailure('networkError');
  }

  @override
  Future<UserProfile?> getProfile(String uid) async => null;
  @override
  Future<UserPreferences?> getPreferences(String uid) async => null;
  @override
  Future<void> updatePreferences(UserPreferences preferences) async {}
  @override
  Future<void> updateProfile(UserProfile profile) async {}
}
