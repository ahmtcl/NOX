import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox/app.dart';
import 'package:nox/core/localization/app_localizations.dart';
import 'package:nox/core/routing/app_router.dart';
import 'package:nox/features/auth/application/auth_controller.dart';
import 'package:nox/features/auth/domain/auth_user.dart';
import 'package:nox/features/discovery/application/discovery_controller.dart';
import 'package:nox/features/discovery/domain/discovery_repository.dart';
import 'package:nox/features/discovery/domain/public_profile.dart';
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
    await tester.pumpWidget(_pageApp(
      _FakeMatches(items: [const NoxMatch(userAUid: 'a', userBUid: 'b')]),
      profiles: {'b': const PublicProfile(uid: 'b', displayName: 'Deniz')},
    ));
    await tester.pumpAndSettle();
    expect(find.text('Deniz'), findsOneWidget);
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
        discoveryRepositoryProvider.overrideWithValue(_FakeDiscovery()),
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

  testWidgets('maps multiple matches in match order with one batch request',
      (tester) async {
    final discovery = _FakeDiscovery(profiles: {
      'b': const PublicProfile(uid: 'b', displayName: 'Deniz'),
      'c': const PublicProfile(uid: 'c', displayName: 'Ece'),
    });
    await tester.pumpWidget(_pageApp(
      _FakeMatches(items: const [
        NoxMatch(userAUid: 'a', userBUid: 'c'),
        NoxMatch(userAUid: 'a', userBUid: 'b'),
      ]),
      discovery: discovery,
    ));
    await tester.pumpAndSettle();
    expect(find.text('Ece'), findsOneWidget);
    expect(find.text('Deniz'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Ece')).dy,
        lessThan(tester.getTopLeft(find.text('Deniz')).dy));
    expect(discovery.batchCalls, 1);
    expect(discovery.requestedIds, {'b', 'c'});
  });

  testWidgets('skips missing profiles safely', (tester) async {
    await tester.pumpWidget(_pageApp(
      _FakeMatches(items: const [NoxMatch(userAUid: 'a', userBUid: 'b')]),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Henüz bir eşleşmen yok.'), findsOneWidget);
  });

  testWidgets('card shows available age, city and accessible semantics',
      (tester) async {
    await tester.pumpWidget(_pageApp(
      _FakeMatches(items: const [NoxMatch(userAUid: 'a', userBUid: 'b')]),
      profiles: {
        'b': const PublicProfile(
            uid: 'b', displayName: 'Deniz', age: 28, city: 'İstanbul'),
      },
    ));
    await tester.pumpAndSettle();
    expect(find.text('28 · İstanbul'), findsOneWidget);
    expect(
        find.bySemanticsLabel('Deniz, 28 yaşında, İstanbul. Eşleştiğin kişi.'),
        findsOneWidget);
  });

  testWidgets('card does not invent missing age or city', (tester) async {
    await tester.pumpWidget(_pageApp(
      _FakeMatches(items: const [NoxMatch(userAUid: 'a', userBUid: 'b')]),
      profiles: {'b': const PublicProfile(uid: 'b', displayName: 'Deniz')},
    ));
    await tester.pumpAndSettle();
    expect(find.text('28 · İstanbul'), findsNothing);
  });

  testWidgets('card uses a safe photo fallback and opens profile detail',
      (tester) async {
    await tester.pumpWidget(_pageApp(
      _FakeMatches(items: const [NoxMatch(userAUid: 'a', userBUid: 'b')]),
      profiles: {
        'b': const PublicProfile(
            uid: 'b', displayName: 'Deniz', photoUrls: ['not-a-url']),
      },
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    await tester.tap(find.text('Deniz'));
    await tester.pumpAndSettle();
    expect(find.text('Profil'), findsOneWidget);
  });

  testWidgets('shows card skeleton while profile batch loads', (tester) async {
    final completer = Completer<Map<String, PublicProfile>>();
    await tester.pumpWidget(_pageApp(
      _FakeMatches(items: const [NoxMatch(userAUid: 'a', userBUid: 'b')]),
      discovery: _FakeDiscovery(completer: completer),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('match-card-skeleton')), findsOneWidget);
    completer.complete({});
  });
}

Widget _pageApp(_FakeMatches repository,
        {Map<String, PublicProfile> profiles = const {},
        _FakeDiscovery? discovery}) =>
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        matchRepositoryProvider.overrideWithValue(repository),
        discoveryRepositoryProvider
            .overrideWithValue(discovery ?? _FakeDiscovery(profiles: profiles)),
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

class _FakeDiscovery implements DiscoveryRepository {
  _FakeDiscovery({this.profiles = const {}, this.completer});
  final Map<String, PublicProfile> profiles;
  final Completer<Map<String, PublicProfile>>? completer;
  var batchCalls = 0;
  Set<String>? requestedIds;

  @override
  Future<Map<String, PublicProfile>> getPublicProfilesByIds(Set<String> uids) {
    batchCalls++;
    requestedIds = uids;
    return completer?.future ?? Future.value(profiles);
  }

  @override
  Future<void> createOrUpdatePublicProfile(PublicProfile profile) async {}

  @override
  Future<DiscoveryPage> getDiscoveryProfiles(
          {required String currentUid,
          Object? cursor,
          int pageSize = 10}) async =>
      const DiscoveryPage(profiles: []);

  @override
  Future<PublicProfile?> getPublicProfile(String uid) async => profiles[uid];
}
