import '../../../core/localization/app_localizations.dart';

String? requiredValue(String? value, AppLocalizations l10n) =>
    value == null || value.isEmpty ? l10n.requiredField : null;

String? emailValue(String? value, AppLocalizations l10n) =>
    value == null || value.isEmpty
        ? l10n.requiredField
        : RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)
            ? null
            : l10n.invalidEmail;
