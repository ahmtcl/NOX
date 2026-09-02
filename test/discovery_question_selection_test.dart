import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nox/features/discovery/domain/discovery_question.dart';
import 'package:nox/features/discovery/domain/discovery_question_pool.dart';
import 'package:nox/features/discovery/domain/discovery_question_selector.dart';

void main() {
  group('DiscoveryQuestionPool', () {
    test('has 45 non-empty, uniquely identified questions', () {
      expect(discoveryQuestionPool.questions, hasLength(45));
      expect(
        discoveryQuestionPool.questions.map((question) => question.id).toSet(),
        hasLength(45),
      );
      expect(
        discoveryQuestionPool.questions.every((question) => question.text.isNotEmpty),
        isTrue,
      );
      for (final category in DiscoveryQuestionCategory.values) {
        expect(discoveryQuestionPool.forCategory(category), hasLength(15));
      }
    });
  });

  group('DiscoveryQuestionSelector', () {
    test('selects one unique question from every category', () {
      final selected = DiscoveryQuestionSelector(random: Random(7)).select(
        pool: discoveryQuestionPool,
      );

      expect(selected, hasLength(3));
      expect(selected.map((question) => question.id).toSet(), hasLength(3));
      for (final category in DiscoveryQuestionCategory.values) {
        expect(selected.where((question) => question.category == category), hasLength(1));
      }
    });

    test('avoids recently used questions when alternatives exist', () {
      final selected = DiscoveryQuestionSelector(random: Random(4)).select(
        pool: discoveryQuestionPool,
        recentlyUsedQuestionIds: [
          'character_001',
          'lifestyle_001',
          'connection_001',
        ],
      );

      expect(selected.map((question) => question.id), isNot(contains('character_001')));
      expect(selected.map((question) => question.id), isNot(contains('lifestyle_001')));
      expect(selected.map((question) => question.id), isNot(contains('connection_001')));
    });

    test('falls back to recent questions when a category has no alternative', () {
      final recentCharacterIds = discoveryQuestionPool
          .forCategory(DiscoveryQuestionCategory.character)
          .map((question) => question.id);
      final selected = DiscoveryQuestionSelector(random: Random(1)).select(
        pool: discoveryQuestionPool,
        recentlyUsedQuestionIds: recentCharacterIds,
      );

      expect(
        selected.singleWhere(
          (question) => question.category == DiscoveryQuestionCategory.character,
        ).id,
        isIn(recentCharacterIds),
      );
    });

    test('returns the same result for the same seeded random input', () {
      final first = DiscoveryQuestionSelector(random: Random(42)).select(
        pool: discoveryQuestionPool,
      );
      final second = DiscoveryQuestionSelector(random: Random(42)).select(
        pool: discoveryQuestionPool,
      );

      expect(first.map((question) => question.id), second.map((question) => question.id));
    });
  });
}
