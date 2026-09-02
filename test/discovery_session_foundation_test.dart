import 'package:flutter_test/flutter_test.dart';
import 'package:nox/features/discovery/domain/discovery_answer.dart';
import 'package:nox/features/discovery/domain/discovery_question.dart';
import 'package:nox/features/discovery/domain/discovery_session.dart';

void main() {
  final timestamp = DateTime.utc(2026, 9, 2);
  final questionIds = ['character-1', 'lifestyle-1', 'connection-1'];

  DiscoverySession session({
    bool userAWantsReveal = false,
    bool userBWantsReveal = false,
    List<String> ids = const ['character-1', 'lifestyle-1', 'connection-1'],
    int currentQuestionIndex = 0,
  }) =>
      DiscoverySession(
        id: DiscoverySession.idFor('user-a', 'user-b'),
        userAUid: 'user-a',
        userBUid: 'user-b',
        status: DiscoverySessionStatus.questions,
        questionIds: ids,
        currentQuestionIndex: currentQuestionIndex,
        userAWantsReveal: userAWantsReveal,
        userBWantsReveal: userBWantsReveal,
        createdAt: timestamp,
        updatedAt: timestamp,
      );

  group('DiscoverySession', () {
    test('uses a participant-order-independent ID', () {
      expect(
        DiscoverySession.idFor('user-a', 'user-b'),
        DiscoverySession.idFor('user-b', 'user-a'),
      );
    });

    test('rejects empty and self participant IDs', () {
      expect(() => DiscoverySession.idFor('', 'user-b'), throwsArgumentError);
      expect(() => DiscoverySession.idFor('user-a', 'user-a'), throwsArgumentError);
    });

    test('requires three unique question IDs and a valid current index', () {
      expect(() => session(ids: questionIds.take(2).toList()), throwsArgumentError);
      expect(() => session(ids: ['q1', 'q1', 'q3']), throwsArgumentError);
      expect(() => session(currentQuestionIndex: -1), throwsArgumentError);
      expect(() => session(currentQuestionIndex: 3), throwsArgumentError);
    });

    test('only treats two reveal requests as mutual', () {
      expect(session().isMutualReveal, isFalse);
      expect(session(userAWantsReveal: true).isMutualReveal, isFalse);
      expect(session(userBWantsReveal: true).isMutualReveal, isFalse);
      expect(
        session(userAWantsReveal: true, userBWantsReveal: true).isMutualReveal,
        isTrue,
      );
    });
  });

  group('DiscoveryAnswer', () {
    test('accepts a valid trimmed answer', () {
      final answer = DiscoveryAnswer(
        sessionId: 'session',
        questionId: 'question',
        userUid: 'user',
        text: '  Merhaba  ',
        createdAt: timestamp,
      );
      expect(answer.text, 'Merhaba');
    });

    test('rejects whitespace-only and overlong answers', () {
      expect(
        () => DiscoveryAnswer(
          sessionId: 'session', questionId: 'question', userUid: 'user', text: '   ', createdAt: timestamp,
        ),
        throwsArgumentError,
      );
      expect(
        () => DiscoveryAnswer(
          sessionId: 'session', questionId: 'question', userUid: 'user', text: 'x' * 301, createdAt: timestamp,
        ),
        throwsArgumentError,
      );
    });
  });

  group('DiscoveryQuestion', () {
    test('accepts a valid question', () {
      final question = DiscoveryQuestion(
        id: 'character-1',
        text: 'Seni en iyi anlatan özellik nedir?',
        category: DiscoveryQuestionCategory.character,
      );
      expect(question.category, DiscoveryQuestionCategory.character);
    });

    test('rejects empty IDs and whitespace-only text', () {
      expect(
        () => DiscoveryQuestion(
          id: '', text: 'Bir soru', category: DiscoveryQuestionCategory.connection,
        ),
        throwsArgumentError,
      );
      expect(
        () => DiscoveryQuestion(
          id: 'question', text: '  ', category: DiscoveryQuestionCategory.connection,
        ),
        throwsArgumentError,
      );
    });
  });
}
