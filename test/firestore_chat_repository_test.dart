import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nox/features/chat/data/firestore_chat_repository.dart';
import 'package:nox/features/chat/domain/chat_repository.dart';
import 'package:nox/features/chat/domain/conversation.dart';
import 'package:nox/features/match/domain/match.dart';
import 'package:nox/features/match/domain/match_repository.dart';
import 'package:nox/features/safety/domain/safety_models.dart';
import 'package:nox/features/safety/domain/safety_repository.dart';

void main() {
  late _MockFirebaseFirestore firestore;
  late _MockCollectionReference conversations;
  late _MockDocumentReference conversation;
  late _MockDocumentSnapshot snapshot;
  late _MockDocumentSnapshot transactionSnapshot;
  late _MockTransaction transaction;
  late _FakeMatchRepository match;
  late _FakeSafetyRepository safety;
  late FirestoreChatRepository repository;
  var transactionExists = false;
  var writes = 0;

  setUp(() {
    firestore = _MockFirebaseFirestore();
    conversations = _MockCollectionReference();
    conversation = _MockDocumentReference();
    snapshot = _MockDocumentSnapshot();
    transactionSnapshot = _MockDocumentSnapshot();
    transaction = _MockTransaction();
    match = _FakeMatchRepository();
    safety = _FakeSafetyRepository();
    repository = FirestoreChatRepository(
      firestore: firestore,
      match: match,
      safety: safety,
    );

    when(() => firestore.collection('conversations')).thenReturn(conversations);
    when(() => conversations.doc('a_b')).thenReturn(conversation);
    when(() => conversation.get()).thenAnswer((_) async => snapshot);
    when(() => snapshot.exists).thenReturn(false);
    when(() => firestore.runTransaction<Conversation>(any()))
        .thenAnswer((invocation) async {
      final handler = invocation.positionalArguments.single
          as Future<Conversation> Function(Transaction);
      return handler(transaction);
    });
    when(() => transaction.get(conversation))
        .thenAnswer((_) async => transactionSnapshot);
    when(() => transactionSnapshot.exists).thenAnswer((_) => transactionExists);
    when(() => transactionSnapshot.data()).thenAnswer((_) => transactionExists
        ? {
            'userAUid': 'a',
            'userBUid': 'b',
            'matchId': 'a_b',
          }
        : null);
    when(() => transaction.set(conversation, any())).thenAnswer((_) {
      transactionExists = true;
      writes++;
    });
  });

  test('writes a new conversation in a transaction', () async {
    final result = await repository.createConversationIfNeeded('a', 'b');

    expect(result.conversationId, 'a_b');
    expect(writes, 1);
    verify(() => transaction.set(conversation, any())).called(1);
  });

  test('returns the conversation found during the transaction', () async {
    transactionExists = true;

    final result = await repository.createConversationIfNeeded('a', 'b');

    expect(result.conversationId, 'a_b');
    expect(writes, 0);
    verifyNever(() => transaction.set(conversation, any()));
  });

  test('uses one deterministic conversation when created twice', () async {
    final first = await repository.createConversationIfNeeded('a', 'b');
    final second = await repository.createConversationIfNeeded('b', 'a');

    expect(first.conversationId, 'a_b');
    expect(second.conversationId, 'a_b');
    expect(writes, 1);
  });

  test('rejects a conversation when A has blocked B', () async {
    safety.blocked.add('a_b');

    await expectLater(
      repository.createConversationIfNeeded('a', 'b'),
      throwsA(isA<ChatFailure>().having((failure) => failure.code, 'code',
          'blocked')),
    );

    expect(safety.checked, ['a_b']);
    expect(match.calls, 0);
    verifyNever(() => firestore.runTransaction<Conversation>(any()));
  });

  test('rejects a conversation when B has blocked A', () async {
    safety.blocked.add('b_a');

    await expectLater(
      repository.createConversationIfNeeded('a', 'b'),
      throwsA(isA<ChatFailure>().having((failure) => failure.code, 'code',
          'blocked')),
    );

    expect(safety.checked, ['a_b', 'b_a']);
    expect(match.calls, 0);
    verifyNever(() => firestore.runTransaction<Conversation>(any()));
  });

  test('continues match validation when neither user is blocked', () async {
    match.value = null;

    await expectLater(
      repository.createConversationIfNeeded('a', 'b'),
      throwsA(isA<ChatFailure>().having(
          (failure) => failure.code, 'code', 'matchNotFound')),
    );

    expect(safety.checked, ['a_b', 'b_a']);
    expect(match.calls, 1);
    verifyNever(() => firestore.runTransaction<Conversation>(any()));
  });

  test('does not check blocks when the conversation already exists', () async {
    when(() => snapshot.exists).thenReturn(true);
    when(() => snapshot.data()).thenReturn({
      'userAUid': 'a',
      'userBUid': 'b',
      'matchId': 'a_b',
    });

    final result = await repository.createConversationIfNeeded('a', 'b');

    expect(result, isA<Conversation>());
    expect(safety.checked, isEmpty);
    expect(match.calls, 0);
  });
}

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class _MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _MockTransaction extends Mock implements Transaction {}

class _FakeMatchRepository implements MatchRepository {
  NoxMatch? value = const NoxMatch(userAUid: 'a', userBUid: 'b');
  var calls = 0;

  @override
  Future<NoxMatch?> createMatchIfNeeded(String a, String b) async => value;

  @override
  Future<NoxMatch?> getMatch(String a, String b) async {
    calls++;
    return value;
  }

  @override
  Future<List<NoxMatch>> getMatches(String uid) async => [];
}

class _FakeSafetyRepository implements SafetyRepository {
  final blocked = <String>{};
  final checked = <String>[];

  @override
  Future<void> blockUser(BlockedUser block) async {}

  @override
  Future<Set<String>> getBlockedUserIds(String uid) async => {};

  @override
  Future<bool> isBlocked(String blockerUid, String blockedUid) async {
    final id = '${blockerUid}_$blockedUid';
    checked.add(id);
    return blocked.contains(id);
  }

  @override
  Future<void> reportUser(UserReport report, {bool alsoBlock = false}) async {}

  @override
  Future<void> unblockUser(BlockedUser block) async {}
}
