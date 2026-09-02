class DiscoveryAnswer {
  factory DiscoveryAnswer({
    required String sessionId,
    required String questionId,
    required String userUid,
    required String text,
    required DateTime createdAt,
  }) {
    final normalizedText = text.trim();
    if (sessionId.trim().isEmpty) {
      throw ArgumentError.value(sessionId, 'sessionId', 'must not be empty');
    }
    if (questionId.trim().isEmpty) {
      throw ArgumentError.value(questionId, 'questionId', 'must not be empty');
    }
    if (userUid.trim().isEmpty) {
      throw ArgumentError.value(userUid, 'userUid', 'must not be empty');
    }
    if (normalizedText.isEmpty || normalizedText.length > maxLength) {
      throw ArgumentError.value(text, 'text', 'must contain 1 to $maxLength characters');
    }
    return DiscoveryAnswer._(
      sessionId: sessionId,
      questionId: questionId,
      userUid: userUid,
      text: normalizedText,
      createdAt: createdAt,
    );
  }

  const DiscoveryAnswer._({
    required this.sessionId,
    required this.questionId,
    required this.userUid,
    required this.text,
    required this.createdAt,
  });

  static const maxLength = 300;

  final String sessionId;
  final String questionId;
  final String userUid;
  final String text;
  final DateTime createdAt;
}
