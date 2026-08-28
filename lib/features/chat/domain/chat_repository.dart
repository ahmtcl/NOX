import 'conversation.dart';

abstract interface class ChatRepository {
  Future<Conversation?> getConversationForMatch(
      String userAUid, String userBUid);
}

class ChatFailure implements Exception {
  const ChatFailure(this.code);
  final String code;
}
