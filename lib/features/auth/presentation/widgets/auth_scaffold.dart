import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/nox_theme.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: NoxGradients.atmosphere),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.appName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                letterSpacing: 6,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: NoxColors.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: NoxColors.elevatedSurface
                                .withValues(alpha: .86),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: NoxColors.lavender.withValues(alpha: .18),
                            ),
                          ),
                          child: child,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline,
                                size: 16, color: NoxColors.cyan),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                l10n.securityMessage,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: NoxColors.textSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.autofillHints,
    this.obscureText = false,
    this.onToggleVisibility,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final Iterable<String> autofillHints;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        autofillHints: autofillHints,
        obscureText: obscureText,
        keyboardType: autofillHints.contains(AutofillHints.email)
            ? TextInputType.emailAddress
            : TextInputType.visiblePassword,
        textInputAction: TextInputAction.next,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: onToggleVisibility == null
              ? null
              : IconButton(
                  tooltip: obscureText ? 'Show password' : 'Hide password',
                  onPressed: onToggleVisibility,
                  icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off),
                ),
        ),
      );
}
