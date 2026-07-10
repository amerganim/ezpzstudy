import 'package:flutter/material.dart';

/// One strong accent color, generous whitespace, large tap targets, high
/// contrast — tuned for a low-end phone with a possibly cracked screen.
class AppTheme {
  static const Color accent = Color(0xFF2E7D6B); // calm teal-green
  static const Color accentDark = Color(0xFF1F5A4C);
  static const Color correct = Color(0xFF2E7D32);
  static const Color incorrect = Color(0xFFC62828);
  static const Color surfaceTint = Color(0xFFF4F7F6);

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
      textTheme: base.textTheme.apply(
        // Slightly larger base sizes; readable Bangla + English.
        fontSizeFactor: 1.05,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56), // large tap target
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
