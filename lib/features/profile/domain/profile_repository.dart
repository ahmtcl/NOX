import '../../auth/domain/auth_user.dart';
import 'profile_setup_draft.dart';
import 'user_profile.dart';

abstract interface class ProfileRepository {
  Future<void> createOrUpdateProfile(AuthUser user, ProfileSetupDraft draft);
  Future<UserProfile?> getProfile(String uid);
  Future<void> updateProfile(UserProfile profile);
  Future<UserPreferences?> getPreferences(String uid);
  Future<void> updatePreferences(UserPreferences preferences);
}

class ProfileFailure implements Exception {
  const ProfileFailure(this.code);
  final String code;
}
