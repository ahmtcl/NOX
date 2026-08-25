import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nox/core/localization/app_localizations.dart';
import 'package:nox/features/onboarding/application/onboarding_providers.dart';
import 'package:nox/features/onboarding/data/onboarding_completion_store.dart';
import 'package:nox/features/onboarding/presentation/onboarding_page.dart';
import 'package:nox/features/splash/presentation/splash_page.dart';

class _MemoryStore implements OnboardingCompletionStore {
  bool completed = false;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async => completed = true;
}

Widget _localizedApp(Widget child) => MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  testWidgets('splash renders the NOX brand', (tester) async {
    final store = _MemoryStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingCompletionStoreProvider.overrideWithValue(store)],
        child: _localizedApp(
          const SplashPage(minimumDisplayDuration: Duration(days: 1)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('NOX'), findsOneWidget);
    expect(find.text('Önce konuş. Bağ kur. Sonra gör.'), findsOneWidget);
  });

  testWidgets('onboarding advances to the next message', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: _localizedApp(const OnboardingPage())),
    );
    await tester.pump();

    expect(find.text('Fotoğraftan önce kişiyi tanı.'), findsOneWidget);
    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    expect(find.text('Önce konuş.'), findsOneWidget);
  });

  testWidgets('completion persists state and moves to auth placeholder',
      (tester) async {
    final store = _MemoryStore();
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const Scaffold(body: Text('auth')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingCompletionStoreProvider.overrideWithValue(store)],
        child: MaterialApp.router(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    for (var index = 0; index < 3; index++) {
      await tester.tap(find.text('Devam et'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text("NOX'a Başla"));
    await tester.pumpAndSettle();

    expect(store.completed, isTrue);
    expect(find.text('auth'), findsOneWidget);
  });

  testWidgets('splash transitions to onboarding for a new user',
      (tester) async {
    final store = _MemoryStore();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashPage(
            minimumDisplayDuration: Duration.zero,
          ),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Scaffold(body: Text('onboarding')),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const Scaffold(body: Text('auth')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingCompletionStoreProvider.overrideWithValue(store)],
        child: MaterialApp.router(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('onboarding'), findsOneWidget);
  });

  test('localization supports Turkish and English onboarding copy', () {
    expect(
      AppLocalizations(const Locale('tr')).onboardingTitle(0),
      'Fotoğraftan önce kişiyi tanı.',
    );
    expect(
      AppLocalizations(const Locale('en')).onboardingTitle(0),
      'Know the person before the photo.',
    );
  });
}
