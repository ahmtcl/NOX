import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../application/auth_controller.dart';
import '../domain/auth_user.dart';
import 'auth_validators.dart';
import 'widgets/auth_scaffold.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next.status == AuthStatus.verificationRequired)
        context.go('/auth/verify-email');
      if (next.status == AuthStatus.authenticated) context.go('/profile/setup');
      if (next.status == AuthStatus.error)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.authError(next.errorCode))));
    });
    return AuthScaffold(
      title: l10n.authWelcome,
      child: Form(
        key: _formKey,
        child: Column(children: [
          AuthTextField(
              controller: _email,
              label: l10n.email,
              autofillHints: const [AutofillHints.email],
              validator: (value) => emailValue(value, l10n)),
          const SizedBox(height: 16),
          AuthTextField(
              controller: _password,
              label: l10n.password,
              autofillHints: const [AutofillHints.password],
              obscureText: _obscurePassword,
              onToggleVisibility: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              validator: (value) => requiredValue(value, l10n)),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: () => context.go('/auth/forgot-password'),
                  child: Text(l10n.forgotPassword))),
          const SizedBox(height: 8),
          FilledButton(
              onPressed: state.isLoading ? null : _submit,
              child: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.login)),
          const SizedBox(height: 16),
          _SocialButtons(disabled: state.isLoading),
          const SizedBox(height: 12),
          Wrap(alignment: WrapAlignment.center, children: [
            Text(l10n.noAccount),
            TextButton(
                onPressed: () => context.go('/auth/register'),
                child: Text(l10n.register))
          ]),
        ]),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate())
      ref
          .read(authControllerProvider.notifier)
          .signIn(_email.text, _password.text);
  }
}

class _SocialButtons extends ConsumerWidget {
  const _SocialButtons({required this.disabled});
  final bool disabled;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(children: [
      OutlinedButton.icon(
          onPressed: disabled
              ? null
              : () =>
                  ref.read(authControllerProvider.notifier).signInWithGoogle(),
          icon: const Icon(Icons.g_mobiledata),
          label: Text(l10n.continueWithGoogle)),
      const SizedBox(height: 8),
      OutlinedButton.icon(
          onPressed: disabled
              ? null
              : () =>
                  ref.read(authControllerProvider.notifier).signInWithApple(),
          icon: const Icon(Icons.apple),
          label: Text(l10n.continueWithApple))
    ]);
  }
}
