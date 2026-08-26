import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/theme/nox_theme.dart';

class NoxApp extends ConsumerWidget {
  const NoxApp({super.key, this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'NOX',
        debugShowCheckedModeBanner: false,
        theme: NoxTheme.light,
        darkTheme: NoxTheme.dark,
        themeMode: ThemeMode.dark,
        locale: locale ?? const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: ref.watch(appRouterProvider),
      );
}
