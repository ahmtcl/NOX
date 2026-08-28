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
        userAUid: _required(data, 'userAUid'),
        userBUid: _required(data, 'userBUid'),
        matchId: _required(data, 'matchId'),
        lastMessagePreview: data['lastMessagePreview'] as String?,
      );
}

String _required(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! String || value.isEmpty) throw FormatException('invalid $key');
  return value;
}
