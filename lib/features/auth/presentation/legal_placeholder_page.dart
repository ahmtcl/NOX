import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import 'widgets/auth_scaffold.dart';

class LegalPlaceholderPage extends StatelessWidget {
  const LegalPlaceholderPage({super.key, required this.isPrivacy});
  final bool isPrivacy;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthScaffold(
      title: isPrivacy ? l10n.privacyPolicyTitle : l10n.termsOfServiceTitle,
      child: Text(
        isPrivacy
            ? l10n.privacyPolicyPlaceholder
            : l10n.termsOfServicePlaceholder,
        textAlign: TextAlign.center,
      ),
    );
  }
}
