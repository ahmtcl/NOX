import 'chat_message.dart';
import 'conversation.dart';

abstract interface class ChatRepository {
  Future<Conversation?> getConversationForMatch(
      String userAUid, String userBUid);
  Future<Conversation> createConversationIfNeeded(
      String userAUid, String userBUid);
  Future<ChatMessage> sendMessage(
      String conversationId, String senderUid, String text);
  Future<ChatMessagePage> getMessages(String conversationId,
      {required String currentUserUid, Object? cursor, int pageSize = 30});
  Stream<List<ChatMessage>> watchMessages(
      String conversationId, String currentUserUid);
}

class ChatMessagePage {
  const ChatMessagePage({required this.messages, this.cursor});
  final List<ChatMessage> messages;
  final Object? cursor;
  bool get hasMore => cursor != null;
}

class ChatFailure implements Exception {
  const ChatFailure(this.code);
  final String code;
}
