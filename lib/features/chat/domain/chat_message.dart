class ChatMessage {
  static const maxLength = 1000;

  ChatMessage({
    required this.messageId,
    required this.conversationId,
    required this.senderUid,
    required this.text,
    this.createdAt,
    this.updatedAt,
  }) {
    if (messageId.isEmpty ||
        conversationId.isEmpty ||
        senderUid.isEmpty ||
        text.trim().isEmpty ||
        text.length > maxLength) {
      throw ArgumentError('invalid chat message');
    }
  }

  final String messageId, conversationId, senderUid, text;
  final DateTime? createdAt, updatedAt;

  Map<String, Object?> toFirestore() => {
        'messageId': messageId,
        'conversationId': conversationId,
        'senderUid': senderUid,
        'text': text,
      };

  factory ChatMessage.fromFirestore(Map<String, dynamic> data) => ChatMessage(
        messageId: data['messageId'] as String,
        conversationId: data['conversationId'] as String,
        senderUid: data['senderUid'] as String,
        text: data['text'] as String,
      );
}
