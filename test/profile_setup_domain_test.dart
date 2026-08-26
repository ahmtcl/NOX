import 'package:flutter_test/flutter_test.dart';
import 'package:nox/core/localization/app_localizations.dart';
import 'package:nox/features/profile/domain/profile_setup_catalog.dart';
import 'package:nox/features/profile/domain/profile_setup_draft.dart';
import 'package:flutter/widgets.dart';

void main() {
  group('Profile setup draft', () {
    test('serializes selections with stable question and option ids', () {
      const draft = ProfileSetupDraft(
        selections: {
          ProfileQuestion.personality: {'curious', 'kind', 'bold'},
        },
        personalAnswer: 'A thoughtful answer',
      );

      final restored = ProfileSetupDraft.fromJson(draft.toJson());

      expect(restored.choicesFor(ProfileQuestion.personality),
          containsAll(['curious', 'kind', 'bold']));
      expect(restored.personalAnswer, 'A thoughtful answer');
    });

    test('catalog preserves the requested personality and selection limits',
        () {
      final personality = profileQuestions.first;

      expect(personality.question, ProfileQuestion.personality);
      expect(personality.choices, hasLength(20));
      expect(personality.minimum, 3);
      expect(personality.maximum, 5);
      expect(profileQuestions, hasLength(10));
    });
  });

  group('Profile localization', () {
    test('offers Turkish and English question and option labels', () {
      final turkish = AppLocalizations(const Locale('tr'));
      final english = AppLocalizations(const Locale('en'));

      expect(turkish.profileQuestion('personality'), isNot('personality'));
      expect(english.profileQuestion('personality'),
          'Which qualities describe you best?');
      expect(turkish.profileOption('curious'), 'Meraklı');
      expect(english.profileOption('curious'), 'Curious');
    });
  });
}
