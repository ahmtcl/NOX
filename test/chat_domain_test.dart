import 'package:flutter_test/flutter_test.dart';
import 'package:nox/features/chat/domain/chat_message.dart';
import 'package:nox/features/chat/domain/conversation.dart';

void main() {
  test('conversation IDs are deterministic and reject invalid users', () {
    expect(Conversation.idFor('a', 'b'), 'a_b');
    expect(Conversation.idFor('b', 'a'), 'a_b');
    expect(() => Conversation.idFor('a', 'a'), throwsArgumentError);
    expect(() => Conversation.idFor('', 'b'), throwsArgumentError);
  });
  test('conversation maps required fields', () {
    final c = Conversation.fromFirestore(
        {'userAUid': 'a', 'userBUid': 'b', 'matchId': 'a_b'});
    expect(c.conversationId, 'a_b');
  });
  test('chat message validates fields and maps', () {
    final m = ChatMessage(
        messageId: 'm', conversationId: 'a_b', senderUid: 'a', text: 'Hello');
    expect(ChatMessage.fromFirestore(m.toFirestore()).text, 'Hello');
    for (final m in [
      () => ChatMessage(
          messageId: '', conversationId: 'c', senderUid: 'a', text: 'x'),
      () => ChatMessage(
          messageId: 'm', conversationId: '', senderUid: 'a', text: 'x'),
      () => ChatMessage(
          messageId: 'm', conversationId: 'c', senderUid: '', text: 'x'),
      () => ChatMessage(
          messageId: 'm', conversationId: 'c', senderUid: 'a', text: '  '),
      () => ChatMessage(
          messageId: 'm',
          conversationId: 'c',
          senderUid: 'a',
          text: 'x' * 1001),
    ]) {
      expect(m, throwsArgumentError);
    }
  });
}
