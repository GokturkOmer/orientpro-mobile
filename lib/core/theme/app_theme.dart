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

class ScadaLightColors {
  // Arka planlar
  static const Color bg = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFF0F2F5);

  // Kenarliklar
  static const Color border = Color(0xFFDDE1E8);
  static const Color borderBright = Color(0xFFBFC6D0);

  // Metin
  static const Color textPrimary = Color(0xFF1A1D21);
  static const Color textSecondary = Color(0xFF5A6577);
  static const Color textDim = Color(0xFF8D99AE);
}

class AppTheme {
  static const Color primaryColor = ScadaColors.cyan;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ScadaLightColors.bg,
      colorScheme: const ColorScheme.light(
        primary: ScadaColors.cyan,
        secondary: ScadaColors.cyanDim,
        surface: ScadaLightColors.surface,
        error: ScadaColors.red,
        onPrimary: Colors.white,
        onSecondary: ScadaLightColors.textPrimary,
        onSurface: ScadaLightColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: ScadaLightColors.surface,
        foregroundColor: ScadaLightColors.textPrimary,
        iconTheme: IconThemeData(color: ScadaColors.cyan),
      ),
      cardTheme: CardThemeData(
        color: ScadaLightColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: ScadaLightColors.border),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ScadaColors.cyan,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ScadaColors.cyan.withValues(alpha: 0.1),
          foregroundColor: ScadaColors.cyan,
          side: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ScadaLightColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ScadaLightColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ScadaLightColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.5)),
        ),
        labelStyle: const TextStyle(color: ScadaLightColors.textSecondary),
        hintStyle: const TextStyle(color: ScadaLightColors.textDim),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ScadaLightColors.surface,
        selectedItemColor: ScadaColors.cyan,
        unselectedItemColor: ScadaLightColors.textDim,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: ScadaLightColors.border,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: ScadaLightColors.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: ScadaLightColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: ScadaLightColors.textPrimary),
        bodyMedium: TextStyle(color: ScadaLightColors.textSecondary),
        bodySmall: TextStyle(color: ScadaLightColors.textDim),
        labelSmall: TextStyle(color: ScadaLightColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1),
      ),
      iconTheme: const IconThemeData(color: ScadaLightColors.textSecondary),
      dialogTheme: DialogThemeData(
        backgroundColor: ScadaLightColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ScadaLightColors.borderBright),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: ScadaLightColors.surface,
        contentTextStyle: TextStyle(color: ScadaLightColors.textPrimary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ScadaColors.cyan,
      ),
    );
  }

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

/// Tema-duyarli renk erişimleri.
/// Kullanim: context.scada.bg, context.scada.textPrimary, vs.
class ThemeAwareColors {
  final BuildContext _context;
  const ThemeAwareColors(this._context);

  bool get _isDark => Theme.of(_context).brightness == Brightness.dark;

  // Arka planlar
  Color get bg => _isDark ? ScadaColors.bg : ScadaLightColors.bg;
  Color get surface => _isDark ? ScadaColors.surface : ScadaLightColors.surface;
  Color get card => _isDark ? ScadaColors.card : ScadaLightColors.card;

  // Kenarliklar
  Color get border => _isDark ? ScadaColors.border : ScadaLightColors.border;
  Color get borderBright => _isDark ? ScadaColors.borderBright : ScadaLightColors.borderBright;

  // Metin
  Color get textPrimary => _isDark ? ScadaColors.textPrimary : ScadaLightColors.textPrimary;
  Color get textSecondary => _isDark ? ScadaColors.textSecondary : ScadaLightColors.textSecondary;
  Color get textDim => _isDark ? ScadaColors.textDim : ScadaLightColors.textDim;

  // Accent renkler — her iki temada ayni
  Color get cyan => ScadaColors.cyan;
  Color get cyanDim => ScadaColors.cyanDim;
  Color get green => ScadaColors.green;
  Color get amber => ScadaColors.amber;
  Color get red => ScadaColors.red;
  Color get purple => ScadaColors.purple;
  Color get orange => ScadaColors.orange;
}

extension ThemeAwareContext on BuildContext {
  ThemeAwareColors get scada => ThemeAwareColors(this);
}
