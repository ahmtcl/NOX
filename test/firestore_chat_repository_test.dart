import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nox/features/chat/data/firestore_chat_repository.dart';
import 'package:nox/features/chat/domain/chat_message.dart';
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
  late _MockCollectionReference messages;
  late _MockDocumentReference message;
  late _MockQuery messageQuery;
  late _MockDocumentSnapshot snapshot;
  late _MockDocumentSnapshot transactionSnapshot;
  late _MockTransaction transaction;
  late _FakeMatchRepository match;
  late _FakeSafetyRepository safety;
  late FirestoreChatRepository repository;
  var transactionExists = false;
  var writes = 0;
  var queryCalls = 0;
  var queryResults = <_MockQuerySnapshot>[];
  late StreamController<_MockQuerySnapshot> streamController;

  setUp(() {
    firestore = _MockFirebaseFirestore();
    conversations = _MockCollectionReference();
    conversation = _MockDocumentReference();
    messages = _MockCollectionReference();
    message = _MockDocumentReference();
    messageQuery = _MockQuery();
    streamController = StreamController<_MockQuerySnapshot>();
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
    when(() => conversation.collection('messages')).thenReturn(messages);
    when(() => messages.doc()).thenReturn(message);
    when(() => message.id).thenReturn('message-id');
    when(() => message.set(any())).thenAnswer((_) async {});
    when(() => messages.orderBy('createdAt', descending: true))
        .thenReturn(messageQuery);
    when(() => messageQuery.limit(any())).thenReturn(messageQuery);
    when(() => messageQuery.startAfterDocument(any())).thenReturn(messageQuery);
    when(() => messageQuery.get()).thenAnswer((_) async {
      return queryResults[queryCalls++];
    });
    when(() => messageQuery.snapshots()).thenAnswer((_) => streamController.stream);
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

  tearDown(() => streamController.close());

  void makeConversationAvailable() {
    when(() => snapshot.exists).thenReturn(true);
    when(() => snapshot.data()).thenReturn({
      'userAUid': 'a',
      'userBUid': 'b',
      'matchId': 'a_b',
    });
  }

  _MockQueryDocumentSnapshot messageDocument(String id, String text) {
    final document = _MockQueryDocumentSnapshot();
    when(() => document.data()).thenReturn({
      'messageId': id,
      'conversationId': 'a_b',
      'senderUid': 'a',
      'text': text,
    });
    return document;
  }

  _MockQuerySnapshot messagePage(List<_MockQueryDocumentSnapshot> documents) {
    final page = _MockQuerySnapshot();
    when(() => page.docs).thenReturn(documents);
    return page;
  }

  test('reads the first message page for a participant', () async {
    makeConversationAvailable();
    queryResults = [messagePage([messageDocument('new', 'newest')])];

    final page =
        await repository.getMessages('a_b', currentUserUid: 'a');

    expect(page.messages.single.text, 'newest');
    expect(page.hasMore, isFalse);
  });

  test('streams messages for a participant with the realtime query', () async {
    makeConversationAvailable();
    final watch = repository.watchMessages('a_b', 'a');
    final next = watch.first;
    streamController.add(messagePage([messageDocument('new', 'newest')]));

    expect((await next).single.text, 'newest');
    verify(() => conversation.collection('messages')).called(1);
    verify(() => messages.orderBy('createdAt', descending: true)).called(1);
    verify(() => messageQuery.limit(30)).called(1);
  });

  test('rejects realtime streams for outsiders', () async {
    makeConversationAvailable();

    await expectLater(repository.watchMessages('a_b', 'outside'),
        emitsError(isA<ChatFailure>().having((f) => f.code, 'code', 'notParticipant')));
  });

  test('rejects realtime streams for missing conversations', () async {
    await expectLater(
        repository.watchMessages('a_b', 'a'),
        emitsError(isA<ChatFailure>()
            .having((f) => f.code, 'code', 'conversationNotFound')));
  });

  test('maps malformed realtime messages to ChatFailure', () async {
    makeConversationAvailable();
    final malformed = _MockQueryDocumentSnapshot();
    when(() => malformed.data()).thenReturn({'messageId': 'bad'});
    final watch = repository.watchMessages('a_b', 'a');
    final error = expectLater(watch,
        emitsError(isA<ChatFailure>().having((f) => f.code, 'code', 'invalidMessage')));
    streamController.add(messagePage([malformed]));
    await error;
  });

  test('maps Firebase realtime errors to ChatFailure', () async {
    makeConversationAvailable();
    final watch = repository.watchMessages('a_b', 'a');
    final error = expectLater(watch,
        emitsError(isA<ChatFailure>().having((f) => f.code, 'code', 'networkError')));
    streamController.addError(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'));
    await error;
  });

  test('reads from the conversation messages subcollection path', () async {
    makeConversationAvailable();
    queryResults = [messagePage([])];

    await repository.getMessages('a_b', currentUserUid: 'a');

    verify(() => conversation.collection('messages')).called(1);
  });

  test('applies the requested message page size', () async {
    makeConversationAvailable();
    queryResults = [messagePage([])];

    await repository.getMessages('a_b', currentUserUid: 'a', pageSize: 2);

    verify(() => messageQuery.limit(2)).called(1);
  });

  test('reads a second message page with its cursor', () async {
    makeConversationAvailable();
    final firstDocument = messageDocument('first', 'first');
    final secondDocument = messageDocument('second', 'second');
    queryResults = [messagePage([firstDocument]), messagePage([secondDocument])];

    final first =
        await repository.getMessages('a_b', currentUserUid: 'a', pageSize: 1);
    final second = await repository.getMessages('a_b',
        currentUserUid: 'a', pageSize: 1, cursor: first.cursor);

    expect(second.messages.single.text, 'second');
    verify(() => messageQuery.startAfterDocument(firstDocument)).called(1);
  });

  test('preserves Firestore newest-first message order', () async {
    makeConversationAvailable();
    queryResults = [messagePage([
      messageDocument('new', 'newest'),
      messageDocument('old', 'oldest'),
    ])];

    final page =
        await repository.getMessages('a_b', currentUserUid: 'a');

    expect(page.messages.map((message) => message.text), ['newest', 'oldest']);
  });

  test('rejects message reads by an outsider', () async {
    makeConversationAvailable();

    await expectLater(
      repository.getMessages('a_b', currentUserUid: 'outside'),
      throwsA(isA<ChatFailure>()
          .having((failure) => failure.code, 'code', 'notParticipant')),
    );

    verifyNever(() => messageQuery.get());
  });

  test('rejects message reads for a missing conversation', () async {
    await expectLater(
      repository.getMessages('a_b', currentUserUid: 'a'),
      throwsA(isA<ChatFailure>()
          .having((failure) => failure.code, 'code', 'conversationNotFound')),
    );

    verifyNever(() => messageQuery.get());
  });

  test('maps malformed messages to a safe failure', () async {
    makeConversationAvailable();
    final malformed = _MockQueryDocumentSnapshot();
    when(() => malformed.data()).thenReturn({'messageId': 'message'});
    queryResults = [messagePage([malformed])];

    await expectLater(
      repository.getMessages('a_b', currentUserUid: 'a'),
      throwsA(isA<ChatFailure>()
          .having((failure) => failure.code, 'code', 'invalidMessage')),
    );
  });

  test('maps Firebase message reads to ChatFailure', () async {
    makeConversationAvailable();
    when(() => messageQuery.get()).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'));

    await expectLater(
      repository.getMessages('a_b', currentUserUid: 'a'),
      throwsA(isA<ChatFailure>()
          .having((failure) => failure.code, 'code', 'networkError')),
    );
  });

  test('writes a message from a valid participant', () async {
    makeConversationAvailable();

    final result = await repository.sendMessage('a_b', 'a', ' hello ');

    expect(result, isA<ChatMessage>());
    expect(result.text, 'hello');
    verify(() => message.set(any())).called(1);
  });

  test('uses the conversation messages subcollection path', () async {
    makeConversationAvailable();

    await repository.sendMessage('a_b', 'a', 'hello');

    verify(() => conversation.collection('messages')).called(1);
    verify(() => messages.doc()).called(1);
    verify(() => message.set(any())).called(1);
  });

  test('does not write a message from an outsider', () async {
    makeConversationAvailable();

    await expectLater(
      repository.sendMessage('a_b', 'outside', 'hello'),
      throwsA(isA<ChatFailure>()
          .having((failure) => failure.code, 'code', 'notParticipant')),
    );

    verifyNever(() => message.set(any()));
  });

  test('rejects a message for a missing conversation', () async {
    await expectLater(
      repository.sendMessage('a_b', 'a', 'hello'),
      throwsA(isA<ChatFailure>()
          .having((failure) => failure.code, 'code', 'conversationNotFound')),
    );

    verifyNever(() => message.set(any()));
  });

  test('rejects an empty message', () async {
    await expectLater(
      repository.sendMessage('a_b', 'a', '   '),
      throwsA(isA<ChatFailure>()
          .having((failure) => failure.code, 'code', 'invalidMessage')),
    );

    verifyNever(() => message.set(any()));
  });

  test('rejects a message longer than 1000 characters', () async {
    await expectLater(
      repository.sendMessage('a_b', 'a', 'x' * 1001),
      throwsA(isA<ChatFailure>()
          .having((failure) => failure.code, 'code', 'invalidMessage')),
    );

    verifyNever(() => message.set(any()));
  });

  test('maps a Firebase write failure to ChatFailure', () async {
    makeConversationAvailable();
    when(() => message.set(any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'));

    await expectLater(
      repository.sendMessage('a_b', 'a', 'hello'),
      throwsA(isA<ChatFailure>()
          .having((failure) => failure.code, 'code', 'networkError')),
    );
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

class _MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class _MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class _MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

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
