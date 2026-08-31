import 'package:flutter/material.dart';

abstract final class NoxColors {
  static const ink = Color(0xFF090A12);
  static const surface = Color(0xFF141625);
  static const elevatedSurface = Color(0xFF20233A);
  static const textPrimary = Color(0xFFF7F6FC);
  static const textSecondary = Color(0xFFB7B5C8);
  static const violet = Color(0xFF8D6BFF);
  static const cyan = Color(0xFF65E8E0);
  static const lavender = Color(0xFFC1B1FF);
  static const success = Color(0xFF66D6A1);
  static const warning = Color(0xFFF1C46A);
  static const danger = Color(0xFFFF6F91);
}

/// The light editorial palette used by the opening and authentication flows.
/// Legacy feature surfaces continue using [NoxColors] until their own redesigns.
abstract final class NoxEditorialColors {
  static const background = Color(0xFFF4F8FF);
  static const backgroundSecondary = Color(0xFFE7F0FF);
  static const stripeLight = Color(0xFFEDF5FF);
  static const stripeBlue = Color(0xFFD5E6FB);
  static const navy = Color(0xFF111D4A);
  static const navySoft = Color(0xFF24345F);
  static const primaryBlue = Color(0xFF397BFF);
  static const primaryBlueLight = Color(0xFF82B5FF);
  static const surface = Colors.white;
  static const textSecondary = Color(0xFF65749A);
  static const border = Color(0x99D5E6FB);
}

abstract final class NoxSpacing {
  static const page = 24.0;
  static const section = 20.0;
  static const field = 14.0;
}

abstract final class NoxRadius {
  static const field = BorderRadius.all(Radius.circular(16));
  static const surface = BorderRadius.all(Radius.circular(24));
}

abstract final class NoxTypography {
  static const editorial = 'serif';
  static const ui = 'sans-serif';
}

abstract final class NoxGradients {
  static const atmosphere = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [NoxColors.ink, Color(0xFF11142A), NoxColors.ink],
  );
  static const accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [NoxColors.violet, NoxColors.cyan],
  );
  static const glow = RadialGradient(
    colors: [Color(0x668D6BFF), Color(0x0065E8E0)],
  );
}

abstract final class NoxTheme {
  static ThemeData get dark => _theme(Brightness.dark, NoxColors.ink);
  static ThemeData get light =>
      _theme(Brightness.light, const Color(0xFFF8F7FC));
  static ThemeData _theme(Brightness brightness, Color background) {
    final scheme = ColorScheme.fromSeed(
      seedColor: NoxColors.violet,
      brightness: brightness,
    ).copyWith(
      primary: NoxColors.violet,
      secondary: NoxColors.cyan,
      surface: brightness == Brightness.dark ? NoxColors.surface : Colors.white,
      onSurface:
          brightness == Brightness.dark ? NoxColors.textPrimary : NoxColors.ink,
    );
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: NoxColors.textPrimary,
            displayColor: NoxColors.textPrimary,
            fontFamily: 'sans-serif',
          ),
      inputDecorationTheme:
          const InputDecorationTheme(border: OutlineInputBorder()),
      cardTheme: const CardThemeData(
        color: NoxColors.elevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
    );
  }
}
