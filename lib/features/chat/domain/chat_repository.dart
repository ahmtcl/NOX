import 'chat_message.dart';
import 'conversation.dart';

abstract interface class ChatRepository {
  Future<Conversation?> getConversationForMatch(
      String userAUid, String userBUid);
  Future<Conversation> createConversationIfNeeded(
      String userAUid, String userBUid);
  Future<ChatMessage> sendMessage(
      String conversationId, String senderUid, String text);
}

class ChatFailure implements Exception {
  const ChatFailure(this.code);
  final String code;
}
