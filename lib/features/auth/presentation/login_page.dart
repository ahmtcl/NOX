import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/nox_theme.dart';
import '../application/auth_controller.dart';
import '../domain/auth_user.dart';
import 'auth_validators.dart';
import 'widgets/auth_scaffold.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.initialMode = AuthMode.login});
  final AuthMode initialMode;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _loginKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  late AuthMode _mode;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    for (final controller in [
      _loginEmail,
      _loginPassword,
      _registerEmail,
      _registerPassword,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next.status == AuthStatus.verificationRequired) context.go('/auth/verify-email');
      if (next.status == AuthStatus.authenticated) context.go('/profile/setup');
      if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.authError(next.errorCode))),
        );
      }
    });
    return AuthScaffold(
      title: l10n.authWelcome,
      mode: _mode,
      showLoginReference: widget.initialMode == AuthMode.login,
      onModeChanged: (value) {
        if (value == AuthMode.register) {
          context.go('/auth/register');
        } else {
          setState(() => _mode = value);
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, .035), end: Offset.zero)
                .animate(animation),
            child: child,
          ),
        ),
        child: _mode == AuthMode.login
            ? _LoginForm(
                key: const ValueKey('login-form'),
                formKey: _loginKey,
                email: _loginEmail,
                password: _loginPassword,
                obscure: _obscure,
                loading: state.isLoading,
                toggle: () => setState(() => _obscure = !_obscure),
                submit: () {
                  if (_loginKey.currentState!.validate()) {
                    ref.read(authControllerProvider.notifier).signIn(
                          _loginEmail.text,
                          _loginPassword.text,
                        );
                  }
                },
              )
            : _RegisterForm(
                key: const ValueKey('register-form'),
                formKey: _registerKey,
                email: _registerEmail,
                password: _registerPassword,
                confirm: _confirmPassword,
                obscure: _obscure,
                loading: state.isLoading,
                toggle: () => setState(() => _obscure = !_obscure),
                submit: () {
                  if (_registerKey.currentState!.validate()) {
                    ref.read(authControllerProvider.notifier).register(
                          _registerEmail.text,
                          _registerPassword.text,
                        );
                  }
                },
              ),
      ),
    );
  }
}

class _LoginForm extends ConsumerWidget {
  const _LoginForm({super.key, required this.formKey, required this.email, required this.password, required this.obscure, required this.loading, required this.toggle, required this.submit});
  final GlobalKey<FormState> formKey;
  final TextEditingController email, password;
  final bool obscure, loading;
  final VoidCallback toggle, submit;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final signInLabel = l.isTurkish ? 'Oturum Aç' : 'Sign in';
    return Form(key: formKey, child: Column(children: [
      AuthTextField(controller: email, label: l.email, autofillHints: const [AutofillHints.email], validator: (v) => emailValue(v, l)),
      const SizedBox(height: 14),
      AuthTextField(controller: password, label: l.password, autofillHints: const [AutofillHints.password], obscureText: obscure, onToggleVisibility: toggle, validator: (v) => requiredValue(v, l)),
      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.go('/auth/forgot-password'), child: Text(l.forgotPassword))),
      _Submit(label: signInLabel, loading: loading, onPressed: submit),
      const SizedBox(height: 16),
      _SocialButtons(disabled: loading),
    ]));
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({super.key, required this.formKey, required this.email, required this.password, required this.confirm, required this.obscure, required this.loading, required this.toggle, required this.submit});
  final GlobalKey<FormState> formKey;
  final TextEditingController email, password, confirm;
  final bool obscure, loading;
  final VoidCallback toggle, submit;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Form(key: formKey, child: Column(children: [
      AuthTextField(controller: email, label: l.email, autofillHints: const [AutofillHints.email], validator: (v) => emailValue(v, l)),
      const SizedBox(height: 14),
      AuthTextField(controller: password, label: l.password, autofillHints: const [AutofillHints.newPassword], obscureText: obscure, onToggleVisibility: toggle, validator: (v) => _strong(v, l)),
      const SizedBox(height: 14),
      AuthTextField(controller: confirm, label: l.confirmPassword, autofillHints: const [AutofillHints.newPassword], obscureText: obscure, onToggleVisibility: toggle, validator: (v) => v == password.text ? null : l.passwordsDoNotMatch),
      const SizedBox(height: 12), Text(l.passwordRequirements, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 8), Text(l.ageRequirement, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 20),
      _Submit(label: l.register, loading: loading, onPressed: submit),
    ]));
  }
}

class _Submit extends StatelessWidget { const _Submit({required this.label, required this.loading, required this.onPressed}); final String label; final bool loading; final VoidCallback onPressed; @override Widget build(BuildContext context) => SizedBox(height: 56, width: double.infinity, child: DecoratedBox(decoration: const BoxDecoration(gradient: LinearGradient(colors: [NoxEditorialColors.primaryBlueLight, NoxEditorialColors.primaryBlue]), borderRadius: NoxRadius.field, boxShadow: [BoxShadow(color: Color(0x22397BFF), blurRadius: 14, offset: Offset(0, 6))]), child: FilledButton(onPressed: loading ? null : onPressed, style: FilledButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.white, shadowColor: Colors.transparent, shape: const RoundedRectangleBorder(borderRadius: NoxRadius.field)), child: loading ? const SizedBox(width: 20,height: 20,child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(label), const SizedBox(width: 8), const Icon(Icons.arrow_forward_rounded, size: 18)])))); }
class _SocialButtons extends ConsumerWidget { const _SocialButtons({required this.disabled}); final bool disabled; @override Widget build(BuildContext context, WidgetRef ref) { final l=AppLocalizations.of(context); return Column(children:[OutlinedButton.icon(onPressed:disabled?null:()=>ref.read(authControllerProvider.notifier).signInWithGoogle(),icon:const Icon(Icons.g_mobiledata),label:Text(l.continueWithGoogle)),const SizedBox(height:8),OutlinedButton.icon(onPressed:disabled?null:()=>ref.read(authControllerProvider.notifier).signInWithApple(),icon:const Icon(Icons.apple),label:Text(l.continueWithApple))]); }}
String? _strong(String? value, AppLocalizations l) => value != null && RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(value) ? null : l.passwordNotStrong;
