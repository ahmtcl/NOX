import 'interaction.dart';

abstract interface class InterestRepository {
  Future<void> submit(Interaction interaction);
  Future<Set<String>> getOutgoingIds(String uid);
  Future<int> incomingCount(String uid, InteractionType type);
}

class InterestFailure implements Exception {
  const InterestFailure(this.code);
  final String code;
}
