import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../application/auth_controller.dart';
import '../domain/auth_user.dart';
import 'auth_validators.dart';
import 'widgets/auth_scaffold.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next.status == AuthStatus.unauthenticated && !_sent)
        setState(() => _sent = true);
      if (next.status == AuthStatus.error)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.authError(next.errorCode))));
    });
    return AuthScaffold(
        title: l10n.forgotPassword,
        child: _sent
            ? Text(l10n.resetSent, textAlign: TextAlign.center)
            : Form(
                key: _formKey,
                child: Column(children: [
                  AuthTextField(
                      controller: _email,
                      label: l10n.email,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) => emailValue(value, l10n)),
                  const SizedBox(height: 20),
                  FilledButton(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _sent = true);
                                ref
                                    .read(authControllerProvider.notifier)
                                    .resetPassword(_email.text);
                              }
                            },
                      child: Text(l10n.resetPassword))
                ])));
  }
}
