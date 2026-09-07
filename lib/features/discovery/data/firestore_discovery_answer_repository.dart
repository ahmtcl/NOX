import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/discovery_answer.dart';
import '../domain/discovery_answer_repository.dart';
import '../domain/discovery_question_answer_state.dart';
import '../domain/discovery_session.dart';

class FirestoreDiscoveryAnswerRepository implements DiscoveryAnswerRepository {
  FirestoreDiscoveryAnswerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<DiscoveryAnswer> submitAnswer({
    required DiscoverySession session,
    required String userUid,
    required String questionId,
    required String text,
  }) async {
    _validateSessionAnswer(session: session, userUid: userUid, questionId: questionId);
    final answer = _answerFor(
      sessionId: session.id,
      questionId: questionId,
      userUid: userUid,
      text: text,
    );
    final reference = _answerReference(answer.sessionId, answer.questionId, answer.userUid);
    try {
      return await _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(reference);
        if (existing.exists) throw const DiscoveryAnswerFailure('alreadyAnswered');
        transaction.set(reference, _answerToFirestore(answer));
        return answer;
      });
    } on FirebaseException catch (error) {
      throw DiscoveryAnswerFailure(
        error.code == 'unavailable' ? 'networkError' : 'answerSaveFailed',
      );
    }
  }

  @override
  Future<DiscoveryAnswer?> getOwnAnswer({
    required String sessionId,
    required String questionId,
    required String userUid,
  }) async {
    final reference = _answerReference(sessionId, questionId, userUid);
    try {
      final document = await reference.get();
      if (!document.exists) return null;
      return _answerFromDocument(
        document.data(),
        sessionId: sessionId,
        questionId: questionId,
        userUid: userUid,
      );
    } on FirebaseException catch (error) {
      throw DiscoveryAnswerFailure(
        error.code == 'unavailable' ? 'networkError' : 'answerLoadFailed',
      );
    }
  }

  @override
  Future<DiscoveryQuestionAnswerState> getQuestionAnswerState({
    required DiscoverySession session,
    required String userUid,
    required String questionId,
  }) async {
    _validateStateRequest(session: session, userUid: userUid, questionId: questionId);
    final ownAnswer = await getOwnAnswer(
      sessionId: session.id,
      questionId: questionId,
      userUid: userUid,
    );
    if (ownAnswer == null) {
      return DiscoveryQuestionAnswerState(ownAnswer: null, otherAnswer: null);
    }
    final otherAnswer = await getOwnAnswer(
      sessionId: session.id,
      questionId: questionId,
      userUid: _otherParticipant(session, userUid),
    );
    return DiscoveryQuestionAnswerState(
      ownAnswer: ownAnswer,
      otherAnswer: otherAnswer,
    );
  }

  void _validateSessionAnswer({
    required DiscoverySession session,
    required String userUid,
    required String questionId,
  }) {
    _validateParticipant(session, userUid);
    if (session.status != DiscoverySessionStatus.questions) {
      throw const DiscoveryAnswerFailure('invalidAnswer');
    }
    _validateQuestion(session, questionId);
    if (session.questionIds[session.currentQuestionIndex] != questionId) {
      throw const DiscoveryAnswerFailure('questionNotActive');
    }
  }

  void _validateStateRequest({
    required DiscoverySession session,
    required String userUid,
    required String questionId,
  }) {
    _validateParticipant(session, userUid);
    _validateQuestion(session, questionId);
  }

  void _validateParticipant(DiscoverySession session, String userUid) {
    if (userUid != session.userAUid && userUid != session.userBUid) {
      throw const DiscoveryAnswerFailure('notParticipant');
    }
  }

  void _validateQuestion(DiscoverySession session, String questionId) {
    if (!session.questionIds.contains(questionId)) {
      throw const DiscoveryAnswerFailure('invalidQuestion');
    }
  }

  String _otherParticipant(DiscoverySession session, String userUid) =>
      userUid == session.userAUid ? session.userBUid : session.userAUid;

  DiscoveryAnswer _answerFor({
    required String sessionId,
    required String questionId,
    required String userUid,
    required String text,
  }) {
    try {
      return DiscoveryAnswer(
        sessionId: sessionId,
        questionId: questionId,
        userUid: userUid,
        text: text,
        createdAt: DateTime.now().toUtc(),
      );
    } on ArgumentError {
      throw const DiscoveryAnswerFailure('invalidAnswer');
    }
  }

  DocumentReference<Map<String, dynamic>> _answerReference(
    String sessionId,
    String questionId,
    String userUid,
  ) {
    try {
      final answerId = DiscoveryAnswer.idFor(questionId, userUid);
      if (sessionId.trim().isEmpty) throw ArgumentError('invalid session ID');
      return _firestore
          .collection('discoverySessions')
          .doc(sessionId)
          .collection('answers')
          .doc(answerId);
    } on ArgumentError {
      throw const DiscoveryAnswerFailure('invalidAnswer');
    }
  }

  DiscoveryAnswer _answerFromDocument(
    Map<String, dynamic>? data, {
    required String sessionId,
    required String questionId,
    required String userUid,
  }) {
    try {
      if (data == null ||
          data['sessionId'] != sessionId ||
          data['questionId'] != questionId ||
          data['userUid'] != userUid ||
          data['text'] is! String ||
          data['createdAt'] is! Timestamp) {
        throw const FormatException('invalid discovery answer');
      }
      return DiscoveryAnswer(
        sessionId: sessionId,
        questionId: questionId,
        userUid: userUid,
        text: data['text'] as String,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    } on ArgumentError {
      throw const DiscoveryAnswerFailure('invalidAnswer');
    } on FormatException {
      throw const DiscoveryAnswerFailure('invalidAnswer');
    } on TypeError {
      throw const DiscoveryAnswerFailure('invalidAnswer');
    }
  }

  Map<String, Object?> _answerToFirestore(DiscoveryAnswer answer) => {
        'sessionId': answer.sessionId,
        'questionId': answer.questionId,
        'userUid': answer.userUid,
        'text': answer.text,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
