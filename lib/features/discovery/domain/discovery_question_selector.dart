import 'dart:math';

import 'discovery_question.dart';
import 'discovery_question_pool.dart';

class DiscoveryQuestionSelector {
  DiscoveryQuestionSelector({Random? random}) : _random = random ?? Random();

  final Random _random;

  List<DiscoveryQuestion> select({
    required DiscoveryQuestionPool pool,
    Iterable<String> recentlyUsedQuestionIds = const [],
  }) {
    final recentlyUsed = recentlyUsedQuestionIds.toSet();
    return [
      for (final category in DiscoveryQuestionCategory.values)
        _pick(pool.forCategory(category), recentlyUsed),
    ];
  }

  DiscoveryQuestion _pick(
    List<DiscoveryQuestion> questions,
    Set<String> recentlyUsedQuestionIds,
  ) {
    final unused = questions
        .where((question) => !recentlyUsedQuestionIds.contains(question.id))
        .toList();
    final candidates = unused.isEmpty ? questions : unused;
    if (candidates.isEmpty) {
      throw ArgumentError('question pool is missing a required category');
    }
    return candidates[_random.nextInt(candidates.length)];
  }
}
