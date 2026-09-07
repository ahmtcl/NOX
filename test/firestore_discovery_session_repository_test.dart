import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nox/features/discovery/data/firestore_discovery_session_repository.dart';
import 'package:nox/features/discovery/domain/discovery_question.dart';
import 'package:nox/features/discovery/domain/discovery_question_pool.dart';
import 'package:nox/features/discovery/domain/discovery_question_selector.dart';
import 'package:nox/features/discovery/domain/discovery_session.dart';
import 'package:nox/features/discovery/domain/discovery_session_repository.dart';

void main() {
  late _MockFirestore firestore;
  late _MockCollection sessions;
  late _MockDocument session;
  late _MockCollection answers;
  late _MockDocument userAAnswer;
  late _MockDocument userBAnswer;
  late _MockSnapshot snapshot;
  late _MockSnapshot transactionSnapshot;
  late _MockSnapshot userAAnswerSnapshot;
  late _MockSnapshot userBAnswerSnapshot;
  late _MockTransaction transaction;
  late _RecordingSelector selector;
  late FirestoreDiscoverySessionRepository repository;
  var transactionExists = false;
  var writes = 0;
  Map<String, Object?>? writtenData;
  var userAAnswered = false;
  var userBAnswered = false;
  Map<String, Object?>? progressionData;

  Map<String, dynamic> validData() => {
        'userAUid': 'a',
        'userBUid': 'b',
        'status': 'questions',
        'questionIds': ['character_001', 'lifestyle_001', 'connection_001'],
        'currentQuestionIndex': 0,
        'userAWantsReveal': false,
        'userBWantsReveal': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

  setUp(() {
    firestore = _MockFirestore();
    sessions = _MockCollection();
    session = _MockDocument();
    answers = _MockCollection();
    userAAnswer = _MockDocument();
    userBAnswer = _MockDocument();
    snapshot = _MockSnapshot();
    transactionSnapshot = _MockSnapshot();
    userAAnswerSnapshot = _MockSnapshot();
    userBAnswerSnapshot = _MockSnapshot();
    transaction = _MockTransaction();
    selector = _RecordingSelector();
    repository = FirestoreDiscoverySessionRepository(
      firestore: firestore,
      questionPool: discoveryQuestionPool,
      questionSelector: selector,
    );

    when(() => firestore.collection('discoverySessions')).thenReturn(sessions);
    when(() => sessions.doc('a_b')).thenReturn(session);
    when(() => session.collection('answers')).thenReturn(answers);
    when(() => answers.doc('character_001_a')).thenReturn(userAAnswer);
    when(() => answers.doc('character_001_b')).thenReturn(userBAnswer);
    when(() => session.get()).thenAnswer((_) async => snapshot);
    when(() => snapshot.exists).thenReturn(false);
    when(() => firestore.runTransaction<DiscoverySession>(any()))
        .thenAnswer((invocation) async {
      final handler = invocation.positionalArguments.single
          as Future<DiscoverySession> Function(Transaction);
      return handler(transaction);
    });
    when(() => transaction.get(session))
        .thenAnswer((_) async => transactionSnapshot);
    when(() => transactionSnapshot.exists).thenAnswer((_) => transactionExists);
    when(() => transactionSnapshot.data())
        .thenAnswer((_) => transactionExists ? validData() : null);
    when(() => transaction.get(userAAnswer)).thenAnswer((_) async {
      when(() => userAAnswerSnapshot.exists).thenReturn(userAAnswered);
      return userAAnswerSnapshot;
    });
    when(() => transaction.get(userBAnswer)).thenAnswer((_) async {
      when(() => userBAnswerSnapshot.exists).thenReturn(userBAnswered);
      return userBAnswerSnapshot;
    });
    when(() => transaction.set(session, any())).thenAnswer((invocation) {
      transactionExists = true;
      writes++;
      writtenData = Map<String, Object?>.from(invocation.positionalArguments[1] as Map);
    });
    when(() => transaction.update(session, any())).thenAnswer((invocation) {
      progressionData = Map<String, Object?>.from(invocation.positionalArguments[1] as Map);
    });
  });

  DiscoverySession sessionFor({
    int index = 0,
    DiscoverySessionStatus status = DiscoverySessionStatus.questions,
  }) {
    final data = validData();
    return DiscoverySession(
      id: 'a_b',
      userAUid: 'a',
      userBUid: 'b',
      status: status,
      questionIds: (data['questionIds'] as List).cast<String>(),
      currentQuestionIndex: index,
      userAWantsReveal: false,
      userBWantsReveal: false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  test('getSession uses the deterministic document ID', () async {
    await repository.getSession('b', 'a');

    verify(() => sessions.doc('a_b')).called(1);
  });

  test('getSession returns null for a missing document', () async {
    expect(await repository.getSession('a', 'b'), isNull);
  });

  test('getSession parses a valid document', () async {
    when(() => snapshot.exists).thenReturn(true);
    when(() => snapshot.data()).thenReturn(validData());

    final result = await repository.getSession('a', 'b');

    expect(result?.id, 'a_b');
    expect(result?.status, DiscoverySessionStatus.questions);
  });

  test('getSession maps malformed documents to a safe failure', () async {
    when(() => snapshot.exists).thenReturn(true);
    when(() => snapshot.data()).thenReturn({'userAUid': 'a'});

    await expectLater(
      repository.getSession('a', 'b'),
      throwsA(isA<DiscoverySessionFailure>().having((f) => f.code, 'code', 'invalidSession')),
    );
  });

  test('creates the expected initial session and stores three questions', () async {
    final result = await repository.createSessionIfNeeded('b', 'a');

    expect(result.id, 'a_b');
    expect(result.userAUid, 'a');
    expect(result.userBUid, 'b');
    expect(result.status, DiscoverySessionStatus.questions);
    expect(result.questionIds, hasLength(3));
    expect(result.currentQuestionIndex, 0);
    expect(result.userAWantsReveal, isFalse);
    expect(result.userBWantsReveal, isFalse);
    expect(writes, 1);
    expect(writtenData?['questionIds'], hasLength(3));
    expect(writtenData?['createdAt'], isA<FieldValue>());
    expect(writtenData?['updatedAt'], isA<FieldValue>());
  });

  test('returns an existing session without overwriting it', () async {
    when(() => snapshot.exists).thenReturn(true);
    when(() => snapshot.data()).thenReturn(validData());

    final result = await repository.createSessionIfNeeded('a', 'b');

    expect(result.id, 'a_b');
    expect(writes, 0);
    verifyNever(() => firestore.runTransaction<DiscoverySession>(any()));
  });

  test('transaction recheck keeps concurrent creates duplicate-safe', () async {
    final first = await repository.createSessionIfNeeded('a', 'b');
    final second = await repository.createSessionIfNeeded('b', 'a');

    expect(first.id, 'a_b');
    expect(second.id, 'a_b');
    expect(writes, 1);
  });

  test('forwards recently used question IDs to the selector', () async {
    await repository.createSessionIfNeeded(
      'a',
      'b',
      recentlyUsedQuestionIds: {'character_001'},
    );

    expect(selector.recentlyUsedQuestionIds, {'character_001'});
  });

  test('rejects empty and self UIDs before Firestore access', () async {
    for (final users in [('', 'b'), ('a', 'a')]) {
      await expectLater(
        repository.getSession(users.$1, users.$2),
        throwsA(isA<DiscoverySessionFailure>().having((f) => f.code, 'code', 'invalidSession')),
      );
    }
    verifyNever(() => sessions.doc(any()));
  });

  test('maps Firebase failures to a safe network failure', () async {
    when(() => session.get()).thenThrow(
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
    );

    await expectLater(
      repository.getSession('a', 'b'),
      throwsA(isA<DiscoverySessionFailure>().having((f) => f.code, 'code', 'networkError')),
    );
  });

  group('advanceQuestion', () {
    setUp(() {
      transactionExists = true;
      userAAnswered = true;
      userBAnswered = true;
    });

    test('moves question 0 to question 1 using a server timestamp write', () async {
      final result = await repository.advanceQuestion(session: sessionFor(), userUid: 'a');

      expect(result.currentQuestionIndex, 1);
      expect(result.status, DiscoverySessionStatus.questions);
      expect(progressionData?['currentQuestionIndex'], 1);
      expect(progressionData?['status'], 'questions');
      expect(progressionData?['updatedAt'], isA<FieldValue>());
      expect(result.questionIds, sessionFor().questionIds);
      expect(result.userAUid, 'a');
      expect(result.userBUid, 'b');
      expect(result.userAWantsReveal, isFalse);
      expect(result.userBWantsReveal, isFalse);
      expect(result.createdAt, sessionFor().createdAt);
    });

    test('moves question 1 to question 2', () async {
      final data = validData()..['currentQuestionIndex'] = 1;
      when(() => transactionSnapshot.data()).thenReturn(data);
      when(() => answers.doc('lifestyle_001_a')).thenReturn(userAAnswer);
      when(() => answers.doc('lifestyle_001_b')).thenReturn(userBAnswer);

      final result = await repository.advanceQuestion(session: sessionFor(index: 1), userUid: 'b');

      expect(result.currentQuestionIndex, 2);
      expect(result.status, DiscoverySessionStatus.questions);
    });

    test('moves completed question 2 to hidden chat without changing its index', () async {
      final data = validData()..['currentQuestionIndex'] = 2;
      when(() => transactionSnapshot.data()).thenReturn(data);
      when(() => answers.doc('connection_001_a')).thenReturn(userAAnswer);
      when(() => answers.doc('connection_001_b')).thenReturn(userBAnswer);

      final result = await repository.advanceQuestion(session: sessionFor(index: 2), userUid: 'a');

      expect(result.currentQuestionIndex, 2);
      expect(result.status, DiscoverySessionStatus.hiddenChat);
    });

    test('rejects each incomplete-answer case', () async {
      userAAnswered = false;
      await expectLater(
        repository.advanceQuestion(session: sessionFor(), userUid: 'a'),
        throwsA(isA<DiscoverySessionFailure>().having((f) => f.code, 'code', 'answersIncomplete')),
      );
      userBAnswered = false;
      await expectLater(
        repository.advanceQuestion(session: sessionFor(), userUid: 'a'),
        throwsA(isA<DiscoverySessionFailure>().having((f) => f.code, 'code', 'answersIncomplete')),
      );
      userAAnswered = true;
      await expectLater(
        repository.advanceQuestion(session: sessionFor(), userUid: 'a'),
        throwsA(isA<DiscoverySessionFailure>().having((f) => f.code, 'code', 'answersIncomplete')),
      );
    });

    test('rejects third parties, stale sessions, and hidden chat', () async {
      await expectLater(
        repository.advanceQuestion(session: sessionFor(), userUid: 'other'),
        throwsA(isA<DiscoverySessionFailure>().having((f) => f.code, 'code', 'notParticipant')),
      );
      final advanced = validData()..['currentQuestionIndex'] = 1;
      when(() => transactionSnapshot.data()).thenReturn(advanced);
      await expectLater(
        repository.advanceQuestion(session: sessionFor(), userUid: 'a'),
        throwsA(isA<DiscoverySessionFailure>().having((f) => f.code, 'code', 'staleSession')),
      );
      final hiddenChat = validData()..['status'] = 'hiddenChat'..['currentQuestionIndex'] = 2;
      when(() => transactionSnapshot.data()).thenReturn(hiddenChat);
      await expectLater(
        repository.advanceQuestion(session: sessionFor(index: 2, status: DiscoverySessionStatus.hiddenChat), userUid: 'a'),
        throwsA(isA<DiscoverySessionFailure>().having((f) => f.code, 'code', 'invalidSession')),
      );
    });

    test('maps Firestore progression errors without leaking Firebase exceptions', () async {
      when(() => firestore.runTransaction<DiscoverySession>(any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );

      await expectLater(
        repository.advanceQuestion(session: sessionFor(), userUid: 'a'),
        throwsA(isA<DiscoverySessionFailure>().having((f) => f.code, 'code', 'sessionProgressFailed')),
      );
    });
  });
}

class _RecordingSelector extends DiscoveryQuestionSelector {
  _RecordingSelector() : super(random: Random(0));

  Set<String>? recentlyUsedQuestionIds;

  @override
  List<DiscoveryQuestion> select({
    required DiscoveryQuestionPool pool,
    Iterable<String> recentlyUsedQuestionIds = const [],
  }) {
    this.recentlyUsedQuestionIds = recentlyUsedQuestionIds.toSet();
    return [
      for (final category in DiscoveryQuestionCategory.values)
        pool.forCategory(category).first,
    ];
  }
}

class _MockFirestore extends Mock implements FirebaseFirestore {}
class _MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}
class _MockDocument extends Mock
    implements DocumentReference<Map<String, dynamic>> {}
class _MockSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}
class _MockTransaction extends Mock implements Transaction {}
