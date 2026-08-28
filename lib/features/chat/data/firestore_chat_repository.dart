import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/chat_repository.dart';
import '../domain/conversation.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  @override
  Future<Conversation?> getConversationForMatch(
      String userAUid, String userBUid) async {
    try {
      final id = Conversation.idFor(userAUid, userBUid);
      final doc = await _firestore.collection('conversations').doc(id).get();
      if (!doc.exists) return null;
      try {
        return Conversation.fromFirestore(doc.data()!);
      } on FormatException {
        throw const ChatFailure('invalidConversation');
      } on ArgumentError {
        throw const ChatFailure('invalidConversation');
      }
    } on FirebaseException catch (e) {
      throw ChatFailure(
          e.code == 'unavailable' ? 'networkError' : 'loadFailed');
    }
  }

  @override
  Future<Conversation> createConversationIfNeeded(
      String userAUid, String userBUid) async {
    final existing = await getConversationForMatch(userAUid, userBUid);
    if (existing != null) return existing;
    final users = [userAUid, userBUid]..sort();
    return Conversation(
        userAUid: users[0],
        userBUid: users[1],
        matchId: Conversation.idFor(userAUid, userBUid));
  }
}
