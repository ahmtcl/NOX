import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import 'widgets/auth_scaffold.dart';

class ProfileSetupPlaceholderPage extends StatelessWidget {
  const ProfileSetupPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthScaffold(
        title: l10n.profileSetupTitle,
        child: Text(l10n.profileSetupBody, textAlign: TextAlign.center));
  }
}
