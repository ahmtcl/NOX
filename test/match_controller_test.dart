import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox/features/auth/application/auth_controller.dart';
import 'package:nox/features/auth/domain/auth_user.dart';
import 'package:nox/features/match/application/match_controller.dart';
import 'package:nox/features/match/domain/match.dart';
import 'package:nox/features/match/domain/match_repository.dart';

void main() {
  test('controller loads, supports empty and retries errors', () async {
    final repo = _FakeMatches([const NoxMatch(userAUid: 'a', userBUid: 'b')]);
    final c = ProviderContainer(overrides: [
      matchRepositoryProvider.overrideWithValue(repo),
      authControllerProvider.overrideWith(_Auth.new)
    ]);
    expect(c.read(matchControllerProvider).isLoading, isTrue);
    await c.read(matchControllerProvider.future);
    expect(c.read(matchControllerProvider).valueOrNull, hasLength(1));
    repo.fail = true;
    await c.read(matchControllerProvider.notifier).retry();
    expect(c.read(matchControllerProvider).hasError, isTrue);
    c.dispose();
  });
}

class _Auth extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
      AuthUser(id: 'a', email: null, emailVerified: true));
}

class _FakeMatches implements MatchRepository {
  _FakeMatches(this.items);
  final List<NoxMatch> items;
  bool fail = false;
  @override
  Future<List<NoxMatch>> getMatches(String uid) async {
    if (fail) throw const MatchFailure('loadFailed');
    return items;
  }

  @override
  Future<NoxMatch?> getMatch(String a, String b) async => null;
  @override
  Future<NoxMatch?> createMatchIfNeeded(String a, String b) async => null;
}
