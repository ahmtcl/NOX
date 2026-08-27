import 'match.dart';

abstract interface class MatchRepository {
  Future<NoxMatch?> getMatch(String a, String b);
  Future<NoxMatch?> createMatchIfNeeded(String a, String b);
  Future<List<NoxMatch>> getMatches(String uid);
}

class MatchFailure implements Exception {
  const MatchFailure(this.code);
  final String code;
}
