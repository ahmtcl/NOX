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
  late _FakeMatchRepository match;
  late _FakeSafetyRepository safety;
  late FirestoreChatRepository repository;

  setUp(() {
    firestore = _MockFirebaseFirestore();
    conversations = _MockCollectionReference();
    conversation = _MockDocumentReference();
    snapshot = _MockDocumentSnapshot();
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
