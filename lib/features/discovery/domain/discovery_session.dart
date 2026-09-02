enum DiscoverySessionStatus { questions, hiddenChat, revealed, closed }

class DiscoverySession {
  factory DiscoverySession({
    required String id,
    required String userAUid,
    required String userBUid,
    required DiscoverySessionStatus status,
    required List<String> questionIds,
    required int currentQuestionIndex,
    required bool userAWantsReveal,
    required bool userBWantsReveal,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final normalizedQuestionIds = questionIds.map((id) => id.trim()).toList();
    _validate(
      id: id,
      userAUid: userAUid,
      userBUid: userBUid,
      questionIds: normalizedQuestionIds,
      currentQuestionIndex: currentQuestionIndex,
    );
    return DiscoverySession._(
      id: id,
      userAUid: userAUid,
      userBUid: userBUid,
      status: status,
      questionIds: List.unmodifiable(normalizedQuestionIds),
      currentQuestionIndex: currentQuestionIndex,
      userAWantsReveal: userAWantsReveal,
      userBWantsReveal: userBWantsReveal,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  const DiscoverySession._({
    required this.id,
    required this.userAUid,
    required this.userBUid,
    required this.status,
    required this.questionIds,
    required this.currentQuestionIndex,
    required this.userAWantsReveal,
    required this.userBWantsReveal,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userAUid;
  final String userBUid;
  final DiscoverySessionStatus status;
  final List<String> questionIds;
  final int currentQuestionIndex;
  final bool userAWantsReveal;
  final bool userBWantsReveal;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isMutualReveal => userAWantsReveal && userBWantsReveal;

  static String idFor(String userAUid, String userBUid) {
    if (userAUid.trim().isEmpty || userBUid.trim().isEmpty || userAUid == userBUid) {
      throw ArgumentError('invalid discovery session users');
    }
    final users = [userAUid, userBUid]..sort();
    return '${users[0]}_${users[1]}';
  }

  static void _validate({
    required String id,
    required String userAUid,
    required String userBUid,
    required List<String> questionIds,
    required int currentQuestionIndex,
  }) {
    if (id.trim().isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    final expectedId = idFor(userAUid, userBUid);
    if (id != expectedId) {
      throw ArgumentError.value(id, 'id', 'must match the participant ID');
    }
    if (questionIds.length != 3) {
      throw ArgumentError.value(questionIds, 'questionIds', 'must contain exactly three IDs');
    }
    if (questionIds.any((id) => id.isEmpty)) {
      throw ArgumentError.value(questionIds, 'questionIds', 'must not contain empty IDs');
    }
    if (questionIds.toSet().length != questionIds.length) {
      throw ArgumentError.value(questionIds, 'questionIds', 'must not contain duplicates');
    }
    if (currentQuestionIndex < 0 || currentQuestionIndex >= questionIds.length) {
      throw ArgumentError.value(currentQuestionIndex, 'currentQuestionIndex', 'must be between 0 and 2');
    }
  }
}
