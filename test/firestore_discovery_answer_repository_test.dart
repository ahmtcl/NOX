import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nox/features/discovery/data/firestore_discovery_answer_repository.dart';
import 'package:nox/features/discovery/domain/discovery_answer.dart';
import 'package:nox/features/discovery/domain/discovery_answer_repository.dart';
import 'package:nox/features/discovery/domain/discovery_session.dart';

void main() {
  late _MockFirestore firestore;
  late _MockCollection sessions;
  late _MockDocument sessionDocument;
  late _MockCollection answers;
  late _MockDocument answerA;
  late _MockDocument answerB;
  late _MockSnapshot snapshotA;
  late _MockSnapshot snapshotB;
  late _MockSnapshot transactionSnapshotA;
  late _MockSnapshot transactionSnapshotB;
  late _MockTransaction transaction;
  late FirestoreDiscoveryAnswerRepository repository;
  var answerAExists = false;
  var answerBExists = false;
  var writes = 0;
  Map<String, Object?>? writtenData;

  final session = DiscoverySession(
    id: 'a_b',
    userAUid: 'a',
    userBUid: 'b',
    status: DiscoverySessionStatus.questions,
    questionIds: const ['character_001', 'lifestyle_001', 'connection_001'],
    currentQuestionIndex: 0,
    userAWantsReveal: false,
    userBWantsReveal: false,
    createdAt: DateTime.utc(2026, 9, 2),
    updatedAt: DateTime.utc(2026, 9, 2),
  );

  Map<String, dynamic> answerData(String uid, String text) => {
        'sessionId': 'a_b',
        'questionId': 'character_001',
        'userUid': uid,
        'text': text,
        'createdAt': Timestamp.now(),
      };

  setUp(() {
    firestore = _MockFirestore();
    sessions = _MockCollection();
    sessionDocument = _MockDocument();
    answers = _MockCollection();
    answerA = _MockDocument();
    answerB = _MockDocument();
    snapshotA = _MockSnapshot();
    snapshotB = _MockSnapshot();
    transactionSnapshotA = _MockSnapshot();
    transactionSnapshotB = _MockSnapshot();
    transaction = _MockTransaction();
    repository = FirestoreDiscoveryAnswerRepository(firestore: firestore);

    when(() => firestore.collection('discoverySessions')).thenReturn(sessions);
    when(() => sessions.doc('a_b')).thenReturn(sessionDocument);
    when(() => sessionDocument.collection('answers')).thenReturn(answers);
    when(() => answers.doc('character_001_a')).thenReturn(answerA);
    when(() => answers.doc('character_001_b')).thenReturn(answerB);
    when(() => answerA.get()).thenAnswer((_) async => snapshotA);
    when(() => answerB.get()).thenAnswer((_) async => snapshotB);
    when(() => snapshotA.exists).thenAnswer((_) => answerAExists);
    when(() => snapshotB.exists).thenAnswer((_) => answerBExists);
    when(() => snapshotA.data()).thenAnswer(
      (_) => answerAExists ? answerData('a', 'A cevabı') : null,
    );
    when(() => snapshotB.data()).thenAnswer(
      (_) => answerBExists ? answerData('b', 'B cevabı') : null,
    );
    when(() => firestore.runTransaction<DiscoveryAnswer>(any()))
        .thenAnswer((invocation) async {
      final handler = invocation.positionalArguments.single
          as Future<DiscoveryAnswer> Function(Transaction);
      return handler(transaction);
    });
    when(() => transaction.get(answerA))
        .thenAnswer((_) async => transactionSnapshotA);
    when(() => transaction.get(answerB))
        .thenAnswer((_) async => transactionSnapshotB);
    when(() => transactionSnapshotA.exists).thenAnswer((_) => answerAExists);
    when(() => transactionSnapshotB.exists).thenAnswer((_) => answerBExists);
    when(() => transaction.set(answerA, any())).thenAnswer((invocation) {
      answerAExists = true;
      writes++;
      writtenData = Map<String, Object?>.from(invocation.positionalArguments[1] as Map);
    });
    when(() => transaction.set(answerB, any())).thenAnswer((_) {
      answerBExists = true;
      writes++;
    });
  });

  Future<DiscoveryAnswer> submit(String uid, String text) => repository.submitAnswer(
        session: session,
        userUid: uid,
        questionId: 'character_001',
        text: text,
      );

  test('uses a deterministic answer ID', () {
    expect(DiscoveryAnswer.idFor('character_001', 'a'), 'character_001_a');
  });

  test('allows either participant to submit the active question', () async {
    final first = await submit('a', '  Merhaba  ');
    final second = await submit('b', 'Selam');

    expect(first.text, 'Merhaba');
    expect(second.userUid, 'b');
    expect(writes, 2);
    expect(writtenData?['createdAt'], isA<FieldValue>());
  });

  test('rejects third parties, invalid questions, and inactive questions', () async {
    await expectLater(
      submit('outside', 'cevap'),
      throwsA(isA<DiscoveryAnswerFailure>().having((f) => f.code, 'code', 'notParticipant')),
    );
    await expectLater(
      repository.submitAnswer(session: session, userUid: 'a', questionId: 'unknown', text: 'cevap'),
      throwsA(isA<DiscoveryAnswerFailure>().having((f) => f.code, 'code', 'invalidQuestion')),
    );
    await expectLater(
      repository.submitAnswer(session: session, userUid: 'a', questionId: 'lifestyle_001', text: 'cevap'),
      throwsA(isA<DiscoveryAnswerFailure>().having((f) => f.code, 'code', 'questionNotActive')),
    );
  });

  test('rejects invalid and duplicate answers without overwriting', () async {
    await expectLater(
      submit('a', '   '),
      throwsA(isA<DiscoveryAnswerFailure>().having((f) => f.code, 'code', 'invalidAnswer')),
    );
    await expectLater(
      submit('a', 'x' * 301),
      throwsA(isA<DiscoveryAnswerFailure>().having((f) => f.code, 'code', 'invalidAnswer')),
    );
    answerAExists = true;
    await expectLater(
      submit('a', 'yeni cevap'),
      throwsA(isA<DiscoveryAnswerFailure>().having((f) => f.code, 'code', 'alreadyAnswered')),
    );
    expect(writes, 0);
  });

  test('hides the other answer without an own answer', () async {
    answerBExists = true;

    final state = await repository.getQuestionAnswerState(
      session: session,
      userUid: 'a',
      questionId: 'character_001',
    );

    expect(state.ownAnswer, isNull);
    expect(state.otherAnswer, isNull);
    expect(state.hasOtherAnswer, isFalse);
    expect(state.canViewOtherAnswer, isFalse);
    verifyNever(() => answerB.get());
  });

  test('returns both answers only after both participants have answered', () async {
    answerAExists = true;
    answerBExists = true;

    final forA = await repository.getQuestionAnswerState(
      session: session,
      userUid: 'a',
      questionId: 'character_001',
    );
    final forB = await repository.getQuestionAnswerState(
      session: session,
      userUid: 'b',
      questionId: 'character_001',
    );

    expect(forA.ownAnswer?.text, 'A cevabı');
    expect(forA.otherAnswer?.text, 'B cevabı');
    expect(forB.ownAnswer?.text, 'B cevabı');
    expect(forB.otherAnswer?.text, 'A cevabı');
    expect(forA.areBothAnswered, isTrue);
    expect(forB.canViewOtherAnswer, isTrue);
  });

  test('rejects third-party state requests and malformed answers safely', () async {
    await expectLater(
      repository.getQuestionAnswerState(session: session, userUid: 'outside', questionId: 'character_001'),
      throwsA(isA<DiscoveryAnswerFailure>().having((f) => f.code, 'code', 'notParticipant')),
    );
    answerAExists = true;
    when(() => snapshotA.data()).thenReturn({'sessionId': 'a_b'});
    await expectLater(
      repository.getOwnAnswer(sessionId: 'a_b', questionId: 'character_001', userUid: 'a'),
      throwsA(isA<DiscoveryAnswerFailure>().having((f) => f.code, 'code', 'invalidAnswer')),
    );
  });

  test('maps Firebase answer failures safely', () async {
    when(() => answerA.get()).thenThrow(
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
    );

    await expectLater(
      repository.getOwnAnswer(sessionId: 'a_b', questionId: 'character_001', userUid: 'a'),
      throwsA(isA<DiscoveryAnswerFailure>().having((f) => f.code, 'code', 'networkError')),
    );
  });
}

class _MockFirestore extends Mock implements FirebaseFirestore {}
class _MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}
class _MockDocument extends Mock
    implements DocumentReference<Map<String, dynamic>> {}
class _MockSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}
class _MockTransaction extends Mock implements Transaction {}
