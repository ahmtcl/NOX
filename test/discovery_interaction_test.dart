import 'dart:async';

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

  testWidgets('Premium user sees the Special Interest reason sheet',
      (tester) async {
    final harness = _Harness(isPremium: true);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await _openReasonSheet(tester);

    expect(find.text('Neden özellikle ilgini çekti?'), findsOneWidget);
    expect(find.textContaining('Bir neden seç.'), findsOneWidget);
    expect(find.text('Kişiliği'), findsOneWidget);
    expect(find.text('Mizahı'), findsOneWidget);
    expect(find.text('Müzik zevki'), findsOneWidget);
    expect(find.text('Yaşam tarzı'), findsOneWidget);
    expect(find.text('Profil enerjisi'), findsOneWidget);
    expect(find.text('Genel olarak ilgimi çekti'), findsOneWidget);
  });

  testWidgets('Only one reason can be selected and submit enables afterwards',
      (tester) async {
    final harness = _Harness(isPremium: true);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openReasonSheet(tester);

    var submit = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Özel İlgi Gönder'));
    expect(submit.onPressed, isNull);

    await tester.tap(find.text('Kişiliği'));
    await tester.pump();
    await tester.tap(find.text('Mizahı'));
    await tester.pump();

    submit = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Özel İlgi Gönder'));
    expect(submit.onPressed, isNotNull);
    expect(find.bySemanticsLabel('Kişiliği, seçilmedi'), findsOneWidget);
    expect(find.bySemanticsLabel('Mizahı, seçildi'), findsOneWidget);
  });

  testWidgets('Special Interest submits selected reason and removes profile',
      (tester) async {
    final harness = _Harness(isPremium: true);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openReasonSheet(tester);
    await tester.tap(find.text('Müzik zevki'));
    await tester.pump();
    await tester.tap(find.text('Özel İlgi Gönder'));
    await tester.pumpAndSettle();

    final item = harness.repository.items.single;
    expect(item.type, InteractionType.specialInterest);
    expect(item.reason, SpecialInterestReason.music);
    expect(harness.container.read(discoveryControllerProvider).valueOrNull,
        isEmpty);
    expect(find.text('✦ Özel İlgi gönderildi.'), findsOneWidget);
  });

  testWidgets('Special Interest prevents duplicate submits while loading',
      (tester) async {
    final completer = Completer<void>();
    final harness = _Harness(isPremium: true, submitCompleter: completer);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openReasonSheet(tester);
    await tester.tap(find.text('Kişiliği'));
    await tester.pump();
    await tester.tap(find.text('Özel İlgi Gönder'));
    await tester.pump();

    expect(find.text('Yükleniyor.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Yükleniyor.'));
    await tester.pump();
    expect(harness.repository.items, hasLength(1));

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'Special Interest repository failure keeps sheet open and is safe',
      (tester) async {
    final harness = _Harness(isPremium: true, shouldFail: true);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openReasonSheet(tester);
    await tester.tap(find.text('Kişiliği'));
    await tester.pump();
    await tester.tap(find.text('Özel İlgi Gönder'));
    await tester.pumpAndSettle();

    expect(
        find.text('Özel İlgi gönderilemedi. Tekrar deneyin.'), findsOneWidget);
    expect(find.text('Neden özellikle ilgini çekti?'), findsOneWidget);
    expect(harness.container.read(discoveryControllerProvider).valueOrNull,
        hasLength(1));
  });

  test('Special Interest localization supports Turkish and English', () {
    final turkish = AppLocalizations(const Locale('tr'));
    final english = AppLocalizations(const Locale('en'));

    expect(turkish.discoverySpecialInterestSend, 'Özel İlgi Gönder');
    expect(english.discoverySpecialInterestSend, 'Send Special Interest');
    expect(english.discoverySpecialInterestReason(SpecialInterestReason.humor),
        'Humor');
  });
}

Future<void> _openReasonSheet(WidgetTester tester) async {
  await tester.tap(find.text('Özel İlgi'));
  await tester.pumpAndSettle();
}

class _Harness {
  factory _Harness(
      {bool isPremium = false,
      bool shouldFail = false,
      Completer<void>? submitCompleter}) {
    final repository = _FakeInterestRepository(
        shouldFail: shouldFail, submitCompleter: submitCompleter);
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
  _FakeInterestRepository({this.shouldFail = false, this.submitCompleter});

  final items = <Interaction>[];
  final bool shouldFail;
  final Completer<void>? submitCompleter;

  @override
  Future<void> submit(Interaction interaction) async {
    items.add(interaction);
    await submitCompleter?.future;
    if (shouldFail) throw const InterestFailure('saveFailed');
  }

  @override
  Future<int> incomingCount(String uid, InteractionType type) async => 0;

  @override
  Future<Set<String>> getOutgoingIds(String uid) async => {};
}
