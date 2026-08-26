import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox/core/localization/app_localizations.dart';
import 'package:nox/features/profile/application/profile_setup_controller.dart';
import 'package:nox/features/profile/data/profile_setup_draft_store.dart';
import 'package:nox/features/profile/domain/profile_setup_draft.dart';
import 'package:nox/features/profile/presentation/profile_setup_page.dart';

void main() {
  testWidgets(
      'renders personality discovery and enforces its five-choice maximum',
      (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('Seni en iyi hangi özellikler anlatır?'), findsOneWidget);
    for (final label in [
      'Meraklı',
      'Komik',
      'Zeki',
      'Sakin',
      'Tutkulu',
      'Gizemli'
    ]) {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
  });

  testWidgets('moves forward after the minimum choices and supports going back',
      (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    for (final label in ['Meraklı', 'Komik', 'Zeki']) {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    expect(find.text('Boş bir akşamın nasıl geçer?'), findsOneWidget);

    await tester.tap(find.text('Geri'));
    await tester.pumpAndSettle();
    expect(find.text('Seni en iyi hangi özellikler anlatır?'), findsOneWidget);
  });
}

Widget _testApp() => ProviderScope(
      overrides: [
        profileSetupDraftStoreProvider.overrideWithValue(_MemoryDraftStore()),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProfileSetupPage(),
      ),
    );

class _MemoryDraftStore implements ProfileSetupDraftStore {
  ProfileSetupDraft value = const ProfileSetupDraft();

  @override
  Future<ProfileSetupDraft> load() async => value;

  @override
  Future<void> save(ProfileSetupDraft draft) async {
    value = draft;
  }

  @override
  Future<void> clear() async {
    value = const ProfileSetupDraft();
  }
}
