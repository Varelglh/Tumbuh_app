import 'package:flutter/material.dart';

class AppTheme {
  static const Color brandGreen = Color(0xFF6B8E23);
  static const Color brandGreenDark = Color(0xFF55711B);
  // Page background (samakan dengan background halaman resep)
  static const Color cream = Color(0xFFF6F6F1);
  static const Color card = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1F2A1F);
  static const Color muted = Color(0xFF6B756B);

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: cream,
      colorScheme: base.colorScheme.copyWith(
        primary: brandGreen,
        secondary: brandGreenDark,
        surface: card,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyLarge: const TextStyle(fontSize: 16, color: ink, height: 1.25),
        bodyMedium: const TextStyle(fontSize: 14, color: muted, height: 1.2),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
