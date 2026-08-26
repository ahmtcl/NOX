import 'safety_models.dart';

abstract interface class SafetyRepository {
  Future<void> blockUser(BlockedUser block);
  Future<void> unblockUser(BlockedUser block);
  Future<Set<String>> getBlockedUserIds(String uid);
  Future<void> reportUser(UserReport report, {bool alsoBlock = false});
  Future<bool> isBlocked(String blockerUid, String blockedUid);
}

class SafetyFailure implements Exception {
  const SafetyFailure(this.code);
  final String code;
}
