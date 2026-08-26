import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../application/auth_controller.dart';
import '../domain/auth_user.dart';
import 'auth_validators.dart';
import 'widgets/auth_scaffold.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next.status == AuthStatus.verificationRequired)
        context.go('/auth/verify-email');
      if (next.status == AuthStatus.error)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.authError(next.errorCode))));
    });
    return AuthScaffold(
        title: l10n.register,
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
                  autofillHints: const [AutofillHints.newPassword],
                  obscureText: _obscure,
                  onToggleVisibility: () =>
                      setState(() => _obscure = !_obscure),
                  validator: (value) => _strongPassword(value, l10n)),
              const SizedBox(height: 16),
              AuthTextField(
                  controller: _confirm,
                  label: l10n.confirmPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  obscureText: _obscure,
                  onToggleVisibility: () =>
                      setState(() => _obscure = !_obscure),
                  validator: (value) => value == _password.text
                      ? null
                      : l10n.passwordsDoNotMatch),
              const SizedBox(height: 12),
              Text(l10n.passwordRequirements,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(l10n.ageRequirement,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: Text(l10n.register)),
              Wrap(alignment: WrapAlignment.center, children: [
                Text(l10n.haveAccount),
                TextButton(
                    onPressed: () => context.go('/auth/login'),
                    child: Text(l10n.login))
              ])
            ])));
  }

  void _submit() {
    if (_formKey.currentState!.validate())
      ref
          .read(authControllerProvider.notifier)
          .register(_email.text, _password.text);
  }
}

String? _strongPassword(String? value, AppLocalizations l10n) =>
    value != null &&
            RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(value)
        ? null
        : l10n.passwordNotStrong;
