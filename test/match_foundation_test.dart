import 'package:flutter_test/flutter_test.dart';
import 'package:nox/features/interest/domain/interaction.dart';
import 'package:nox/features/match/domain/match.dart';
import 'package:nox/features/match/domain/match_repository.dart';

void main() {
  test('match id is deterministic and rejects invalid users', () {
    expect(NoxMatch.idFor('a', 'b'), NoxMatch.idFor('b', 'a'));
    expect(() => NoxMatch.idFor('a', 'a'), throwsArgumentError);
    expect(() => NoxMatch.idFor('', 'b'), throwsArgumentError);
  });
  test('match maps active status and server timestamps safely', () {
    final match = NoxMatch.fromFirestore(
        {'userAUid': 'a', 'userBUid': 'b', 'status': 'active'});
    expect(match.matchId, 'a_b');
    expect(match.status, MatchStatus.active);
    expect(match.createdAt, isNull);
  });
  test('mutual interest types create a match but pass does not', () {
    for (final pair in [
      (InteractionType.like, InteractionType.like),
      (InteractionType.like, InteractionType.specialInterest),
      (InteractionType.specialInterest, InteractionType.like),
      (InteractionType.specialInterest, InteractionType.specialInterest)
    ]) {
      expect(_isMutual(pair.$1, pair.$2), isTrue);
    }
    expect(_isMutual(InteractionType.pass, InteractionType.like), isFalse);
    expect(_isMutual(InteractionType.like, InteractionType.pass), isFalse);
  });
  test('fake repository prevents blocked and duplicate matches', () async {
    final repository = _FakeMatchRepository();
    expect(await repository.createMatchIfNeeded('a', 'blocked'), isNull);
    final first = await repository.createMatchIfNeeded('a', 'b');
    final second = await repository.createMatchIfNeeded('b', 'a');
    expect(first?.matchId, 'a_b');
    expect(second?.matchId, 'a_b');
    expect(repository.matches, hasLength(1));
  });
}

bool _isMutual(InteractionType a, InteractionType b) =>
    a != InteractionType.pass && b != InteractionType.pass;

class _FakeMatchRepository implements MatchRepository {
  final matches = <String, NoxMatch>{};
  @override
  Future<NoxMatch?> createMatchIfNeeded(String a, String b) async {
    if (a == 'blocked' || b == 'blocked') return null;
    final id = NoxMatch.idFor(a, b);
    return matches.putIfAbsent(id, () {
      final u = [a, b]..sort();
      return NoxMatch(userAUid: u[0], userBUid: u[1]);
    });
  }

  @override
  Future<NoxMatch?> getMatch(String a, String b) async =>
      matches[NoxMatch.idFor(a, b)];
  @override
  Future<List<NoxMatch>> getMatches(String uid) async => matches.values
      .where((m) => m.userAUid == uid || m.userBUid == uid)
      .toList();
}
