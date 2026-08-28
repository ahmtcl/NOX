import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox/app.dart';
import 'package:nox/core/localization/app_localizations.dart';
import 'package:nox/core/routing/app_router.dart';
import 'package:nox/features/auth/application/auth_controller.dart';
import 'package:nox/features/auth/domain/auth_user.dart';
import 'package:nox/features/match/application/match_controller.dart';
import 'package:nox/features/match/domain/match.dart';
import 'package:nox/features/match/domain/match_repository.dart';
import 'package:nox/features/match/presentation/match_page.dart';
import 'package:nox/features/profile/application/profile_completion_provider.dart';

void main() {
  testWidgets('MatchPage shows loading', (tester) async {
    final completer = Completer<List<NoxMatch>>();
    await tester.pumpWidget(_pageApp(_FakeMatches(completer: completer)));
    await tester.pump();
    expect(find.text('Eşleşmeler yükleniyor.'), findsOneWidget);
    completer.complete(const []);
  });

  testWidgets('MatchPage shows loaded matches', (tester) async {
    await tester.pumpWidget(_pageApp(_FakeMatches(items: [
      const NoxMatch(userAUid: 'a', userBUid: 'b'),
    ])));
    await tester.pumpAndSettle();
    expect(find.text('a_b'), findsOneWidget);
    expect(find.text('active'), findsOneWidget);
  });

  testWidgets('MatchPage shows empty state', (tester) async {
    await tester.pumpWidget(_pageApp(_FakeMatches()));
    await tester.pumpAndSettle();
    expect(find.text('Henüz bir eşleşmen yok.'), findsOneWidget);
    expect(find.text('Keşfetmeye Devam Et'), findsOneWidget);
  });

  testWidgets('MatchPage shows an error and retries', (tester) async {
    final repo = _FakeMatches(fail: true);
    await tester.pumpWidget(_pageApp(repo));
    await tester.pumpAndSettle();
    expect(find.text('Eşleşmeler şu anda yüklenemiyor.'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Tekrar Dene'));
    await tester.pumpAndSettle();
    expect(find.text('Henüz bir eşleşmen yok.'), findsOneWidget);
  });

  testWidgets('/matches is an authenticated route', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        profileCompletionProvider.overrideWith((_) async => true),
        matchRepositoryProvider.overrideWithValue(_FakeMatches()),
      ],
      child: const NoxApp(),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(NoxApp)));
    container.read(appRouterProvider).go('/matches');
    await tester.pumpAndSettle();
    expect(find.text('Eşleşmeler'), findsOneWidget);
  });

  test('match localization supports Turkish and English', () {
    expect(AppLocalizations(const Locale('tr')).matchesTitle, 'Eşleşmeler');
    expect(AppLocalizations(const Locale('en')).matchesTitle, 'Matches');
    expect(AppLocalizations(const Locale('en')).matchesRetry, 'Try again');
  });
}

Widget _pageApp(_FakeMatches repository) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        matchRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MatchPage(),
      ),
    );

class _Auth extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
      AuthUser(id: 'a', email: null, emailVerified: true));
}

class _FakeMatches implements MatchRepository {
  _FakeMatches({this.items = const [], this.fail = false, this.completer});
  final List<NoxMatch> items;
  bool fail;
  final Completer<List<NoxMatch>>? completer;

  @override
  Future<List<NoxMatch>> getMatches(String uid) {
    if (fail) return Future.error(const MatchFailure('loadFailed'));
    return completer?.future ?? Future.value(items);
  }

  @override
  Future<NoxMatch?> createMatchIfNeeded(String a, String b) async => null;

  @override
  Future<NoxMatch?> getMatch(String a, String b) async => null;
}
