import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/nox_theme.dart';

class ProfileHomePlaceholderPage extends StatelessWidget {
  const ProfileHomePlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: NoxGradients.atmosphere),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: NoxColors.success, size: 48),
                  const SizedBox(height: 18),
                  Text(l10n.homePlaceholderTitle,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(l10n.homePlaceholderBody,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: NoxColors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
