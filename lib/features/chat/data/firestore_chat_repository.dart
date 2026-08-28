import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/chat_repository.dart';
import '../domain/conversation.dart';
import '../../match/data/firestore_match_repository.dart';
import '../../match/domain/match.dart';
import '../../match/domain/match_repository.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository(
      {FirebaseFirestore? firestore, MatchRepository? match})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _match = match ?? FirestoreMatchRepository();
  final FirebaseFirestore _firestore;
  final MatchRepository _match;

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
    if (userAUid.isEmpty || userBUid.isEmpty || userAUid == userBUid) {
      throw const ChatFailure('invalidConversation');
    }
    final existing = await getConversationForMatch(userAUid, userBUid);
    if (existing != null) return existing;
    final match = await _match.getMatch(userAUid, userBUid);
    if (match == null) throw const ChatFailure('matchNotFound');
    if (match.status != MatchStatus.active ||
        !{match.userAUid, match.userBUid}.contains(userAUid) ||
        !{match.userAUid, match.userBUid}.contains(userBUid)) {
      throw const ChatFailure('invalidMatch');
    }
    final users = [userAUid, userBUid]..sort();
    return Conversation(
        userAUid: users[0],
        userBUid: users[1],
        matchId: Conversation.idFor(userAUid, userBUid));
  }
}
