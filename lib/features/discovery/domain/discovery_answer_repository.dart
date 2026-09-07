import 'discovery_answer.dart';
import 'discovery_question_answer_state.dart';
import 'discovery_session.dart';

abstract interface class DiscoveryAnswerRepository {
  Future<DiscoveryAnswer> submitAnswer({
    required DiscoverySession session,
    required String userUid,
    required String questionId,
    required String text,
  });

  Future<DiscoveryAnswer?> getOwnAnswer({
    required String sessionId,
    required String questionId,
    required String userUid,
  });

  Future<DiscoveryQuestionAnswerState> getQuestionAnswerState({
    required DiscoverySession session,
    required String userUid,
    required String questionId,
  });
}

class DiscoveryAnswerFailure implements Exception {
  const DiscoveryAnswerFailure(this.code);

  final String code;
}
