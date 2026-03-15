import 'package:flutter/material.dart';

class ScadaColors {
  // Arka planlar
  static const Color bg = Color(0xFF0a0d12);
  static const Color surface = Color(0xFF111620);
  static const Color card = Color(0xFF161c28);

  // Kenarlıklar
  static const Color border = Color(0xFF1e2a3a);
  static const Color borderBright = Color(0xFF2a3f58);

  // Vurgu
  static const Color cyan = Color(0xFF00d4ff);
  static const Color cyanDim = Color(0xFF0099bb);

  // Durum
  static const Color green = Color(0xFF00e676);
  static const Color amber = Color(0xFFf5a623);
  static const Color red = Color(0xFFff4444);
  static const Color purple = Color(0xFFa855f7);
  static const Color orange = Color(0xFFff6b35);

  // Metin
  static const Color textPrimary = Color(0xFFe8f0fe);
  static const Color textSecondary = Color(0xFF7a8fa6);
  static const Color textDim = Color(0xFF3d5068);
}

class AppTheme {
  static const Color primaryColor = ScadaColors.cyan;

  static ThemeData get lightTheme => darkTheme;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ScadaColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: ScadaColors.cyan,
        secondary: ScadaColors.cyanDim,
        surface: ScadaColors.surface,
        error: ScadaColors.red,
        onPrimary: ScadaColors.bg,
        onSecondary: ScadaColors.textPrimary,
        onSurface: ScadaColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: ScadaColors.surface,
        foregroundColor: ScadaColors.textPrimary,
        iconTheme: IconThemeData(color: ScadaColors.cyan),
      ),
      cardTheme: CardThemeData(
        color: ScadaColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: ScadaColors.border),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ScadaColors.cyan,
        foregroundColor: ScadaColors.bg,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ScadaColors.cyan.withValues(alpha: 0.15),
          foregroundColor: ScadaColors.cyan,
          side: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ScadaColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ScadaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ScadaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.5)),
        ),
        labelStyle: const TextStyle(color: ScadaColors.textSecondary),
        hintStyle: const TextStyle(color: ScadaColors.textDim),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ScadaColors.surface,
        selectedItemColor: ScadaColors.cyan,
        unselectedItemColor: ScadaColors.textDim,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: ScadaColors.border,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: ScadaColors.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: ScadaColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: ScadaColors.textPrimary),
        bodyMedium: TextStyle(color: ScadaColors.textSecondary),
        bodySmall: TextStyle(color: ScadaColors.textDim),
        labelSmall: TextStyle(color: ScadaColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1),
      ),
      iconTheme: const IconThemeData(color: ScadaColors.textSecondary),
      dialogTheme: DialogThemeData(
        backgroundColor: ScadaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ScadaColors.borderBright),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: ScadaColors.surface,
        contentTextStyle: TextStyle(color: ScadaColors.textPrimary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ScadaColors.cyan,
      ),
    );
  }
}
