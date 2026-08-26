import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox/core/localization/app_localizations.dart';
import 'package:nox/core/theme/nox_theme.dart';
import 'package:nox/features/auth/application/auth_controller.dart';
import 'package:nox/features/auth/domain/auth_user.dart';
import 'package:nox/features/discovery/application/discovery_controller.dart';
import 'package:nox/features/discovery/domain/public_profile.dart';
import 'package:nox/features/discovery/presentation/discovery_page.dart';
import 'package:nox/features/interest/application/interest_controller.dart';
import 'package:nox/features/interest/domain/interaction.dart';
import 'package:nox/features/interest/domain/interest_repository.dart';

void main() {
  testWidgets('Discovery card shows its three interaction actions',
      (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    expect(find.text('Geç'), findsOneWidget);
    expect(find.text('İlgimi Çekti'), findsOneWidget);
    expect(find.text('Özel İlgi'), findsOneWidget);
  });

  testWidgets('Pass sends an interaction and removes the local profile',
      (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Geç'));
    await tester.pumpAndSettle();

    expect(harness.repository.items.single.type, InteractionType.pass);
    expect(harness.container.read(discoveryControllerProvider).valueOrNull,
        isEmpty);
  });

  testWidgets('Like sends an interaction and removes the local profile',
      (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('İlgimi Çekti'));
    await tester.pumpAndSettle();

    expect(harness.repository.items.single.type, InteractionType.like);
    expect(harness.container.read(discoveryControllerProvider).valueOrNull,
        isEmpty);
  });

  testWidgets('Free user sees the Special Interest premium gate',
      (tester) async {
    final harness = _Harness(isPremium: false);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Özel İlgi'));
    await tester.pumpAndSettle();

    expect(find.text('Bu kişiye diğerlerinden farklı olduğunu hissettir.'),
        findsOneWidget);
    expect(find.text("Premium'u Keşfet"), findsOneWidget);
    expect(find.text('Şimdi Değil'), findsOneWidget);
    expect(harness.repository.items, isEmpty);
  });
}

class _Harness {
  factory _Harness({bool isPremium = false}) {
    final repository = _FakeInterestRepository();
    return _Harness._(
        isPremium: isPremium,
        repository: repository,
        container: ProviderContainer(overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
          discoveryControllerProvider
              .overrideWith(_TestDiscoveryController.new),
          interestRepositoryProvider.overrideWithValue(repository),
          premiumStateProvider.overrideWithValue(isPremium),
        ]));
  }

  _Harness._(
      {required this.isPremium,
      required this.container,
      required this.repository});

  final bool isPremium;
  final ProviderContainer container;
  final _FakeInterestRepository repository;

  Widget app() {
    return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            theme: NoxTheme.dark,
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DiscoveryPage()));
  }
}

class _TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
      AuthUser(id: 'current-user', email: 'test@nox.app', emailVerified: true));
}

class _TestDiscoveryController extends DiscoveryController {
  @override
  Future<List<PublicProfile>> build() async =>
      const [PublicProfile(uid: 'profile-1', displayName: 'Ada', age: 26)];
}

class _FakeInterestRepository implements InterestRepository {
  final items = <Interaction>[];

  @override
  Future<void> submit(Interaction interaction) async => items.add(interaction);

  @override
  Future<int> incomingCount(String uid, InteractionType type) async => 0;

  @override
  Future<Set<String>> getOutgoingIds(String uid) async => {};
}
