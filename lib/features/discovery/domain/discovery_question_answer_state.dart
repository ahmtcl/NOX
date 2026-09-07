import 'discovery_answer.dart';

class DiscoveryQuestionAnswerState {
  factory DiscoveryQuestionAnswerState({
    required DiscoveryAnswer? ownAnswer,
    required DiscoveryAnswer? otherAnswer,
  }) =>
      DiscoveryQuestionAnswerState._(
        ownAnswer: ownAnswer,
        otherAnswer: ownAnswer == null ? null : otherAnswer,
      );

  const DiscoveryQuestionAnswerState._({
    required this.ownAnswer,
    required this.otherAnswer,
  });

  final DiscoveryAnswer? ownAnswer;
  final DiscoveryAnswer? otherAnswer;

  bool get hasOwnAnswer => ownAnswer != null;
  bool get hasOtherAnswer => otherAnswer != null;
  bool get areBothAnswered => hasOwnAnswer && hasOtherAnswer;
  bool get canViewOtherAnswer => areBothAnswered;
}
