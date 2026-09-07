import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/discovery_answer.dart';
import '../domain/discovery_question_pool.dart';
import '../domain/discovery_question_selector.dart';
import '../domain/discovery_session.dart';
import '../domain/discovery_session_repository.dart';

class FirestoreDiscoverySessionRepository
    implements DiscoverySessionRepository {
  FirestoreDiscoverySessionRepository({
    FirebaseFirestore? firestore,
    DiscoveryQuestionPool? questionPool,
    DiscoveryQuestionSelector? questionSelector,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _questionPool = questionPool ?? discoveryQuestionPool,
        _questionSelector = questionSelector ?? DiscoveryQuestionSelector();

  static const _collection = 'discoverySessions';

  final FirebaseFirestore _firestore;
  final DiscoveryQuestionPool _questionPool;
  final DiscoveryQuestionSelector _questionSelector;

  @override
  Future<DiscoverySession?> getSession(String userAUid, String userBUid) async {
    final id = _sessionIdFor(userAUid, userBUid);
    try {
      final document = await _firestore.collection(_collection).doc(id).get();
      if (!document.exists) return null;
      return _sessionFromDocument(id, document.data());
    } on FirebaseException catch (error) {
      throw DiscoverySessionFailure(
        error.code == 'unavailable' ? 'networkError' : 'sessionLoadFailed',
      );
    }
  }

  @override
  Future<DiscoverySession> createSessionIfNeeded(
    String userAUid,
    String userBUid, {
    Set<String> recentlyUsedQuestionIds = const {},
  }) async {
    final id = _sessionIdFor(userAUid, userBUid);
    final existing = await getSession(userAUid, userBUid);
    if (existing != null) return existing;

    final questionIds = _questionSelector
        .select(
          pool: _questionPool,
          recentlyUsedQuestionIds: recentlyUsedQuestionIds,
        )
        .map((question) => question.id)
        .toList();
    final users = [userAUid, userBUid]..sort();
    final now = DateTime.now().toUtc();
    final candidate = DiscoverySession(
      id: id,
      userAUid: users[0],
      userBUid: users[1],
      status: DiscoverySessionStatus.questions,
      questionIds: questionIds,
      currentQuestionIndex: 0,
      userAWantsReveal: false,
      userBWantsReveal: false,
      createdAt: now,
      updatedAt: now,
    );
    final reference = _firestore.collection(_collection).doc(id);
    try {
      return await _firestore.runTransaction((transaction) async {
        final document = await transaction.get(reference);
        if (document.exists) {
          return _sessionFromDocument(id, document.data());
        }
        transaction.set(reference, _sessionToFirestore(candidate));
        return candidate;
      });
    } on FirebaseException catch (error) {
      throw DiscoverySessionFailure(
        error.code == 'unavailable' ? 'networkError' : 'sessionSaveFailed',
      );
    }
  }

  @override
  Future<DiscoverySession> advanceQuestion({
    required DiscoverySession session,
    required String userUid,
  }) async {
    if (userUid.trim().isEmpty) {
      throw const DiscoverySessionFailure('invalidSession');
    }
    if (userUid != session.userAUid && userUid != session.userBUid) {
      throw const DiscoverySessionFailure('notParticipant');
    }

    final reference = _firestore.collection(_collection).doc(session.id);
    try {
      return await _firestore.runTransaction((transaction) async {
        final document = await transaction.get(reference);
        if (!document.exists) {
          throw const DiscoverySessionFailure('invalidSession');
        }
        final current = _sessionFromDocument(session.id, document.data());
        if (userUid != current.userAUid && userUid != current.userBUid) {
          throw const DiscoverySessionFailure('notParticipant');
        }
        if (current.status != DiscoverySessionStatus.questions ||
            current.currentQuestionIndex < 0 ||
            current.currentQuestionIndex > 2) {
          throw const DiscoverySessionFailure('invalidSession');
        }
        // A second tap with an out-of-date session must not advance another
        // question after the first transaction has committed.
        if (current.currentQuestionIndex != session.currentQuestionIndex ||
            current.status != session.status) {
          throw const DiscoverySessionFailure('staleSession');
        }

        final questionId = current.questionIds[current.currentQuestionIndex];
        final answers = reference.collection('answers');
        final userAAnswer = answers.doc(DiscoveryAnswer.idFor(questionId, current.userAUid));
        final userBAnswer = answers.doc(DiscoveryAnswer.idFor(questionId, current.userBUid));
        final answerSnapshots = await Future.wait([
          transaction.get(userAAnswer),
          transaction.get(userBAnswer),
        ]);
        if (!answerSnapshots[0].exists || !answerSnapshots[1].exists) {
          throw const DiscoverySessionFailure('answersIncomplete');
        }

        final isLastQuestion = current.currentQuestionIndex == 2;
        final nextIndex = isLastQuestion ? 2 : current.currentQuestionIndex + 1;
        final nextStatus = isLastQuestion
            ? DiscoverySessionStatus.hiddenChat
            : DiscoverySessionStatus.questions;
        transaction.update(reference, {
          'currentQuestionIndex': nextIndex,
          'status': nextStatus.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return _progressedSession(current, nextIndex, nextStatus);
      });
    } on DiscoverySessionFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw DiscoverySessionFailure(
        error.code == 'unavailable' ? 'networkError' : 'sessionProgressFailed',
      );
    }
  }

  DiscoverySession _progressedSession(
    DiscoverySession session,
    int currentQuestionIndex,
    DiscoverySessionStatus status,
  ) =>
      DiscoverySession(
        id: session.id,
        userAUid: session.userAUid,
        userBUid: session.userBUid,
        status: status,
        questionIds: session.questionIds,
        currentQuestionIndex: currentQuestionIndex,
        userAWantsReveal: session.userAWantsReveal,
        userBWantsReveal: session.userBWantsReveal,
        createdAt: session.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );

  String _sessionIdFor(String userAUid, String userBUid) {
    try {
      return DiscoverySession.idFor(userAUid, userBUid);
    } on ArgumentError {
      throw const DiscoverySessionFailure('invalidSession');
    }
  }

  DiscoverySession _sessionFromDocument(String id, Map<String, dynamic>? data) {
    try {
      if (data == null) throw const FormatException('missing session data');
      final questionIds = data['questionIds'];
      if (questionIds is! List || !questionIds.every((value) => value is String)) {
        throw const FormatException('invalid question IDs');
      }
      final createdAt = data['createdAt'];
      final updatedAt = data['updatedAt'];
      if (createdAt is! Timestamp || updatedAt is! Timestamp) {
        throw const FormatException('invalid timestamps');
      }
      final statusName = data['status'];
      if (statusName is! String ||
          data['userAUid'] is! String ||
          data['userBUid'] is! String ||
          data['currentQuestionIndex'] is! int ||
          data['userAWantsReveal'] is! bool ||
          data['userBWantsReveal'] is! bool) {
        throw const FormatException('invalid session fields');
      }
      return DiscoverySession(
        id: id,
        userAUid: data['userAUid'] as String,
        userBUid: data['userBUid'] as String,
        status: DiscoverySessionStatus.values.byName(statusName),
        questionIds: questionIds.cast<String>(),
        currentQuestionIndex: data['currentQuestionIndex'] as int,
        userAWantsReveal: data['userAWantsReveal'] as bool,
        userBWantsReveal: data['userBWantsReveal'] as bool,
        createdAt: createdAt.toDate(),
        updatedAt: updatedAt.toDate(),
      );
    } on ArgumentError {
      throw const DiscoverySessionFailure('invalidSession');
    } on FormatException {
      throw const DiscoverySessionFailure('invalidSession');
    } on StateError {
      throw const DiscoverySessionFailure('invalidSession');
    } on TypeError {
      throw const DiscoverySessionFailure('invalidSession');
    }
  }

  Map<String, Object?> _sessionToFirestore(DiscoverySession session) => {
        'userAUid': session.userAUid,
        'userBUid': session.userBUid,
        'status': session.status.name,
        'questionIds': session.questionIds,
        'currentQuestionIndex': session.currentQuestionIndex,
        'userAWantsReveal': session.userAWantsReveal,
        'userBWantsReveal': session.userBWantsReveal,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
