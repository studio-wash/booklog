import 'package:flutter/material.dart';

/// Light “grass on white” product theme (plan ref: `plan/.../260512_sample_by_gpt.png` samples ~2, ~8).
/// White-forward surfaces; primary green for heatmap / actions; no layout changes.
ThemeData buildBooklogLightTheme() {
  const grass = Color(0xFF2E7D32); // green 800 — readable on white
  const grassBright = Color(0xFF43A047); // green 600 — FAB / emphasis

  final scheme = ColorScheme.fromSeed(
    seedColor: grassBright,
    brightness: Brightness.light,
    primary: grass,
    onPrimary: Colors.white,
    secondary: const Color(0xFF66BB6A),
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: const Color(0xFF1C1B1F),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: const Color(0xFFE8F5E9),
      iconTheme: IconThemeData(color: scheme.primary),
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: grassBright,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE8E8E8),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1B5E20),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF7FAF7),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
  );
}
