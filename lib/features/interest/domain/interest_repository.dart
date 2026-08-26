import 'interaction.dart';

abstract interface class InterestRepository {
  Future<void> submit(Interaction interaction);
  Future<Set<String>> getOutgoingIds(String uid);
  Future<int> incomingCount(String uid, InteractionType type);
  Future<IncomingInterestSummary> incomingSummary(String uid);
}

class IncomingInterestSummary {
  const IncomingInterestSummary({this.likes = 0, this.specialInterests = 0});
  final int likes;
  final int specialInterests;
  bool get isEmpty => likes == 0 && specialInterests == 0;
}

class InterestFailure implements Exception {
  const InterestFailure(this.code);
  final String code;
}
