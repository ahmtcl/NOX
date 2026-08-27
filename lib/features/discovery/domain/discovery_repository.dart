import 'public_profile.dart';

class DiscoveryPage {
  const DiscoveryPage({required this.profiles, this.cursor});
  final List<PublicProfile> profiles;
  final Object? cursor;
  bool get hasMore => cursor != null;
}

abstract interface class DiscoveryRepository {
  Future<PublicProfile?> getPublicProfile(String uid);
  Future<Map<String, PublicProfile>> getPublicProfilesByIds(Set<String> uids);
  Future<DiscoveryPage> getDiscoveryProfiles(
      {required String currentUid, Object? cursor, int pageSize = 10});
  Future<void> createOrUpdatePublicProfile(PublicProfile profile);
}

class DiscoveryFailure implements Exception {
  const DiscoveryFailure(this.code);
  final String code;
}
