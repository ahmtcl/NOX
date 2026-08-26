import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../application/auth_controller.dart';
import '../domain/auth_user.dart';
import 'widgets/auth_scaffold.dart';

class VerifyEmailPage extends ConsumerWidget {
  const VerifyEmailPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) context.go('/profile/setup');
      if (next.status == AuthStatus.error)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.authError(next.errorCode))));
    });
    return AuthScaffold(
        title: l10n.verificationTitle,
        child: Column(children: [
          Text(l10n.verificationBody(state.user?.email),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(
              onPressed: state.isLoading
                  ? null
                  : () => ref
                      .read(authControllerProvider.notifier)
                      .checkVerification(),
              child: Text(l10n.checkVerification)),
          TextButton(
              onPressed: state.isLoading
                  ? null
                  : () => ref
                      .read(authControllerProvider.notifier)
                      .resendVerification(),
              child: Text(l10n.resendVerification)),
          TextButton(
              onPressed: state.isLoading
                  ? null
                  : () => ref.read(authControllerProvider.notifier).signOut(),
              child: Text(l10n.logout))
        ]));
  }
}
