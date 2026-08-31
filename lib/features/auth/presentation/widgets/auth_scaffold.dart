import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/nox_theme.dart';
import '../../../../core/theme/nox_stripe_background.dart';

enum AuthMode { login, register }

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.mode,
    this.onModeChanged,
    this.showLoginReference = false,
  });

  final String title;
  final Widget child;
  final AuthMode? mode;
  final ValueChanged<AuthMode>? onModeChanged;
  final bool showLoginReference;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const NoxStripeBackground(blur: 1.4),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: NoxSpacing.page,
                  vertical: NoxSpacing.section,
                ),
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
                          if (showLoginReference)
                            SizedBox(
                              height: 236,
                              child: Image.asset(
                                'assets/branding/nox_brand_overlay.png',
                                fit: BoxFit.contain,
                              ),
                            )
                          else ...[
                            Text(
                              l10n.appName,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    color: NoxEditorialColors.navy,
                                    letterSpacing: 6,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (mode != null) ...[
                            Text(
                              l10n.authEditorialFirst,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: NoxEditorialColors.navy,
                                    fontFamily: NoxTypography.editorial,
                                  ),
                            ),
                            Text(
                              l10n.authEditorialSecond,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: NoxEditorialColors.navySoft,
                                    fontFamily: NoxTypography.editorial,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            _AuthSelector(
                              mode: mode!,
                              onChanged: onModeChanged!,
                            ),
                          ] else ...[
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: NoxEditorialColors.navySoft),
                            ),
                            const SizedBox(height: 28),
                          ],
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(NoxSpacing.section),
                            decoration: BoxDecoration(
                              color: NoxEditorialColors.surface.withValues(alpha: .68),
                              borderRadius: NoxRadius.surface,
                              border: Border.all(color: NoxEditorialColors.border),
                              boxShadow: showLoginReference ? const [
                                BoxShadow(
                                  color: Color(0x1424355F),
                                  blurRadius: 22,
                                  offset: Offset(0, 8),
                                ),
                              ] : null,
                            ),
                            child: child,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_outline,
                                  size: 16, color: NoxEditorialColors.primaryBlue),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  l10n.securityMessage,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: NoxEditorialColors.textSecondary,
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
        ],
      ),
    );
  }
}

class _AuthSelector extends StatelessWidget {
  const _AuthSelector({required this.mode, required this.onChanged});

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: NoxEditorialColors.surface.withValues(alpha: .48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NoxEditorialColors.border),
      ),
      child: Row(
        children: [
          for (final value in AuthMode.values)
            Expanded(
              child: _AuthTab(
                label: value == AuthMode.login
                    ? (l10n.isTurkish ? 'Oturum Aç' : l10n.login)
                    : (l10n.isTurkish ? 'Hesap Oluştur' : l10n.register),
                icon: value == AuthMode.login
                    ? Icons.account_circle_outlined
                    : Icons.add,
                selected: value == mode,
                onPressed: () => onChanged(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  const _AuthTab({
    required this.label,
    required this.selected,
    required this.onPressed,
    required this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? NoxEditorialColors.surface : Colors.transparent,
          gradient: selected
              ? const LinearGradient(colors: [Colors.white, Color(0xFFE8F2FF)])
              : null,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x14397BFF), blurRadius: 10)]
              : null,
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: NoxEditorialColors.navy,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18),
            const SizedBox(width: 7),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      );
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
          labelStyle: const TextStyle(color: NoxEditorialColors.textSecondary),
          prefixIcon: Icon(
            autofillHints.contains(AutofillHints.email)
                ? Icons.mail_outline
                : Icons.lock_outline,
            color: NoxEditorialColors.navySoft,
            size: 20,
          ),
          filled: true,
          fillColor: NoxEditorialColors.surface.withValues(alpha: .78),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          enabledBorder: const OutlineInputBorder(
            borderRadius: NoxRadius.field,
            borderSide: BorderSide(color: NoxEditorialColors.border),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: NoxRadius.field,
            borderSide: BorderSide(
              color: NoxEditorialColors.primaryBlue,
              width: 1.4,
            ),
          ),
          suffixIcon: onToggleVisibility == null
              ? null
              : IconButton(
                  tooltip: obscureText ? 'Show password' : 'Hide password',
                  onPressed: onToggleVisibility,
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: NoxEditorialColors.navySoft,
                  ),
                ),
        ),
      );
}
