class Conversation {
  const Conversation({
    required this.userAUid,
    required this.userBUid,
    required this.matchId,
    this.createdAt,
    this.updatedAt,
    this.lastMessageAt,
    this.lastMessagePreview,
  }) : assert(userAUid != '' && userBUid != '' && userAUid != userBUid);

  final String userAUid;
  final String userBUid;
  final String matchId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;

  String get conversationId => idFor(userAUid, userBUid);

  static String idFor(String a, String b) {
    if (a.isEmpty || b.isEmpty || a == b) {
      throw ArgumentError('invalid conversation users');
    }
    final users = [a, b]..sort();
    return '${users[0]}_${users[1]}';
  }

  Map<String, Object?> toFirestore() => {
        'userAUid': userAUid,
        'userBUid': userBUid,
        'matchId': matchId,
        if (lastMessagePreview != null)
          'lastMessagePreview': lastMessagePreview,
      };

  factory Conversation.fromFirestore(Map<String, dynamic> data) => Conversation(
        userAUid: data['userAUid'] as String,
        userBUid: data['userBUid'] as String,
        matchId: data['matchId'] as String,
        lastMessagePreview: data['lastMessagePreview'] as String?,
      );
}
