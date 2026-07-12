import 'package:flutter/material.dart';

/// One strong accent color, generous whitespace, large tap targets, high
/// contrast — tuned for a low-end phone with a possibly cracked screen.
class AppTheme {
  static const Color accent = Color(0xFF2E7D6B); // calm teal-green
  static const Color accentDark = Color(0xFF1F5A4C);
  static const Color correct = Color(0xFF2E7D32);
  static const Color incorrect = Color(0xFFC62828);
  static const Color surfaceTint = Color(0xFFF4F7F6);
  static const Color hairline = Color(0xFFE2E8E6); // subtle card/divider border
  static const Color ink = Color(0xFF1A2420); // near-black body text

  static ThemeData light() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
    );
    return base.copyWith(
      // Bump text slightly for readability. We can't use
      // TextTheme.apply(fontSizeFactor:) because some Material 3 styles carry a
      // null fontSize, which trips a debug assertion; scale only the styles that
      // define a size, leaving the rest untouched.
      textTheme: _scaleDefinedSizes(base.textTheme, 1.05),
      // Clean, flat header: solid white, no M3 surface tint, bold centered
      // title — reads as a purpose-built app rather than a default scaffold.
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: accentDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: accentDark,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54), // large tap target
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: accentDark,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          side: const BorderSide(color: accent, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      // Crisp white cards with a hairline border instead of flat grey fills —
      // separates content cleanly on the white scaffold.
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: hairline),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  /// Multiplies the font size of every text style that defines one, leaving
  /// styles with a null fontSize alone (scaling those asserts in debug).
  static TextTheme _scaleDefinedSizes(TextTheme theme, double factor) {
    TextStyle? scale(TextStyle? s) => s?.fontSize == null
        ? s
        : s!.copyWith(fontSize: s.fontSize! * factor);
    return theme.copyWith(
      displayLarge: scale(theme.displayLarge),
      displayMedium: scale(theme.displayMedium),
      displaySmall: scale(theme.displaySmall),
      headlineLarge: scale(theme.headlineLarge),
      headlineMedium: scale(theme.headlineMedium),
      headlineSmall: scale(theme.headlineSmall),
      titleLarge: scale(theme.titleLarge),
      titleMedium: scale(theme.titleMedium),
      titleSmall: scale(theme.titleSmall),
      bodyLarge: scale(theme.bodyLarge),
      bodyMedium: scale(theme.bodyMedium),
      bodySmall: scale(theme.bodySmall),
      labelLarge: scale(theme.labelLarge),
      labelMedium: scale(theme.labelMedium),
      labelSmall: scale(theme.labelSmall),
    );
  }
}
