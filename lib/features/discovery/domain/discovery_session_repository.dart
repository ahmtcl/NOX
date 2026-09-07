import 'discovery_session.dart';

abstract interface class DiscoverySessionRepository {
  Future<DiscoverySession?> getSession(String userAUid, String userBUid);

  Future<DiscoverySession> createSessionIfNeeded(
    String userAUid,
    String userBUid, {
    Set<String> recentlyUsedQuestionIds = const {},
  });

  /// Advances a completed question exactly once.
  ///
  /// The supplied session supplies the caller's expected question index; the
  /// repository re-reads the session and answers transactionally before any
  /// state change is made.
  Future<DiscoverySession> advanceQuestion({
    required DiscoverySession session,
    required String userUid,
  });
}

class DiscoverySessionFailure implements Exception {
  const DiscoverySessionFailure(this.code);

  final String code;
}
