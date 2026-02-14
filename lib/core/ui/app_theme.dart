// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

class AppTheme {
  // ✅ Paleta (premium dark)
  static const Color bg = Color(0xFF0B0F14);
  static const Color card = Color(0xFF121826);

  static const Color text = Color(0xFFE8EEF6);
  static const Color muted = Color(0xFF9AA6B2);

  // Accent principal (Delta-like)
  static const Color accent = Color(0xFFFFD60A);

  // Señales
  static const Color green = Color(0xFF34C759);
  static const Color red = Color(0xFFFF3B30);

  static ThemeData darkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: IconThemeData(color: text),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle:
            const TextStyle(color: text, fontWeight: FontWeight.w700),
        actionTextColor: accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.08),
        thickness: 1,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(color: text, fontWeight: FontWeight.w900),
        titleMedium: const TextStyle(color: text, fontWeight: FontWeight.w900),
        bodyLarge: const TextStyle(color: text),
        bodyMedium: const TextStyle(color: text),
        bodySmall: const TextStyle(color: muted),
      ),
      iconTheme: const IconThemeData(color: text),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: bg,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: accent,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: bg,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        hintStyle: TextStyle(color: muted.withOpacity(0.85)),
        labelStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.2),
        ),
      ),
    );
  }
}
