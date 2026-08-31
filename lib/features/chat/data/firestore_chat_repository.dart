import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/conversation.dart';
import '../../match/data/firestore_match_repository.dart';
import '../../match/domain/match.dart';
import '../../match/domain/match_repository.dart';
import '../../safety/data/firestore_safety_repository.dart';
import '../../safety/domain/safety_repository.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository(
      {FirebaseFirestore? firestore,
      MatchRepository? match,
      SafetyRepository? safety})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _match = match ?? FirestoreMatchRepository(),
        _safety = safety ?? FirestoreSafetyRepository();
  final FirebaseFirestore _firestore;
  final MatchRepository _match;
  final SafetyRepository _safety;

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
    if (await _safety.isBlocked(userAUid, userBUid) ||
        await _safety.isBlocked(userBUid, userAUid)) {
      throw const ChatFailure('blocked');
    }
    final match = await _match.getMatch(userAUid, userBUid);
    if (match == null) throw const ChatFailure('matchNotFound');
    if (match.status != MatchStatus.active ||
        !{match.userAUid, match.userBUid}.contains(userAUid) ||
        !{match.userAUid, match.userBUid}.contains(userBUid)) {
      throw const ChatFailure('invalidMatch');
    }
    final users = [userAUid, userBUid]..sort();
    final conversation = Conversation(
        userAUid: users[0],
        userBUid: users[1],
        matchId: Conversation.idFor(userAUid, userBUid));
    final ref = _firestore.collection('conversations').doc(conversation.matchId);
    try {
      return await _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(ref);
        if (existing.exists) {
          try {
            return Conversation.fromFirestore(existing.data()!);
          } on FormatException {
            throw const ChatFailure('invalidConversation');
          } on ArgumentError {
            throw const ChatFailure('invalidConversation');
          }
        }
        transaction.set(ref, {
          ...conversation.toFirestore(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return conversation;
      });
    } on FirebaseException catch (e) {
      throw ChatFailure(
          e.code == 'unavailable' ? 'networkError' : 'saveFailed');
    }
  }

  @override
  Future<ChatMessage> sendMessage(
      String conversationId, String senderUid, String text) async {
    if (conversationId.isEmpty) throw const ChatFailure('invalidMessage');
    final conversationRef =
        _firestore.collection('conversations').doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc();
    final message = _messageFor(
        messageRef.id, conversationId, senderUid, text.trim());
    try {
      final snapshot = await conversationRef.get();
      if (!snapshot.exists) throw const ChatFailure('conversationNotFound');
      final conversation = _conversationFrom(snapshot.data()!);
      if (conversation.conversationId != conversationId ||
          conversation.matchId != conversationId) {
        throw const ChatFailure('invalidConversation');
      }
      if (senderUid != conversation.userAUid &&
          senderUid != conversation.userBUid) {
        throw const ChatFailure('notParticipant');
      }
      await messageRef.set({
        ...message.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return message;
    } on FirebaseException catch (e) {
      throw ChatFailure(
          e.code == 'unavailable' ? 'networkError' : 'saveFailed');
    }
  }

  @override
  Future<ChatMessagePage> getMessages(String conversationId,
      {required String currentUserUid,
      Object? cursor,
      int pageSize = 30}) async {
    if (conversationId.isEmpty || currentUserUid.isEmpty) {
      throw const ChatFailure('invalidConversation');
    }
    if (pageSize <= 0 || pageSize > 100) {
      throw const ChatFailure('invalidPageSize');
    }
    DocumentSnapshot<Object?>? firestoreCursor;
    if (cursor != null) {
      if (cursor is! DocumentSnapshot<Object?>) {
        throw const ChatFailure('invalidCursor');
      }
      firestoreCursor = cursor;
    }
    final conversationRef =
        _firestore.collection('conversations').doc(conversationId);
    try {
      final snapshot = await conversationRef.get();
      if (!snapshot.exists) throw const ChatFailure('conversationNotFound');
      final conversation = _conversationFrom(snapshot.data()!);
      if (conversation.conversationId != conversationId ||
          conversation.matchId != conversationId) {
        throw const ChatFailure('invalidConversation');
      }
      if (currentUserUid != conversation.userAUid &&
          currentUserUid != conversation.userBUid) {
        throw const ChatFailure('notParticipant');
      }
      Query<Map<String, dynamic>> query = conversationRef
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(pageSize);
      if (firestoreCursor != null) {
        query = query.startAfterDocument(firestoreCursor);
      }
      final result = await query.get();
      final messages = <ChatMessage>[];
      for (final document in result.docs) {
        try {
          messages.add(ChatMessage.fromFirestore(document.data()));
        } on ArgumentError {
          throw const ChatFailure('invalidMessage');
        } on FormatException {
          throw const ChatFailure('invalidMessage');
        } on TypeError {
          throw const ChatFailure('invalidMessage');
        }
      }
      return ChatMessagePage(
          messages: messages,
          cursor: result.docs.length == pageSize ? result.docs.last : null);
    } on FirebaseException catch (e) {
      throw ChatFailure(
          e.code == 'unavailable' ? 'networkError' : 'loadFailed');
    }
  }

  @override
  Stream<List<ChatMessage>> watchMessages(
      String conversationId, String currentUserUid) async* {
    if (conversationId.isEmpty || currentUserUid.isEmpty) {
      throw const ChatFailure('invalidConversation');
    }
    final conversationRef =
        _firestore.collection('conversations').doc(conversationId);
    try {
      final snapshot = await conversationRef.get();
      if (!snapshot.exists) throw const ChatFailure('conversationNotFound');
      final conversation = _conversationFrom(snapshot.data()!);
      if (conversation.conversationId != conversationId ||
          conversation.matchId != conversationId) {
        throw const ChatFailure('invalidConversation');
      }
      if (currentUserUid != conversation.userAUid &&
          currentUserUid != conversation.userBUid) {
        throw const ChatFailure('notParticipant');
      }
      final query = conversationRef
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(30);
      await for (final result in query.snapshots()) {
        final messages = <ChatMessage>[];
        for (final document in result.docs) {
          try {
            messages.add(ChatMessage.fromFirestore(document.data()));
          } on ArgumentError {
            throw const ChatFailure('invalidMessage');
          } on FormatException {
            throw const ChatFailure('invalidMessage');
          } on TypeError {
            throw const ChatFailure('invalidMessage');
          }
        }
        yield messages;
      }
    } on FirebaseException catch (e) {
      throw ChatFailure(
          e.code == 'unavailable' ? 'networkError' : 'loadFailed');
    }
  }

  ChatMessage _messageFor(
      String messageId, String conversationId, String senderUid, String text) {
    try {
      return ChatMessage(
          messageId: messageId,
          conversationId: conversationId,
          senderUid: senderUid,
          text: text);
    } on ArgumentError {
      throw const ChatFailure('invalidMessage');
    }
  }

  Conversation _conversationFrom(Map<String, dynamic> data) {
    try {
      return Conversation.fromFirestore(data);
    } on FormatException {
      throw const ChatFailure('invalidConversation');
    } on ArgumentError {
      throw const ChatFailure('invalidConversation');
    }
  }
}
