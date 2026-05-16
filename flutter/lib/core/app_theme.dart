import 'package:flutter/material.dart';

/// Light Reading Tracker theme (PLAN-000006 reference.png).
/// **UI chrome**: white background, black/gray text & actions.
/// **Green only** for the reading heatmap — see [grass_github_palette.dart].
ThemeData buildBooklogLightTheme() {
  const ink = Color(0xFF1C1B1F);
  const inkMuted = Color(0xFF5F6368);
  const border = Color(0xFFE0E0E0);
  const cardFill = Color(0xFFF5F5F5);
  const selectedFill = Color(0xFFF0F0F0);

  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: ink,
    onPrimary: Colors.white,
    primaryContainer: selectedFill,
    onPrimaryContainer: ink,
    secondary: inkMuted,
    onSecondary: Colors.white,
    secondaryContainer: cardFill,
    onSecondaryContainer: ink,
    surface: Colors.white,
    onSurface: ink,
    onSurfaceVariant: inkMuted,
    outline: border,
    outlineVariant: border,
    surfaceContainerHighest: cardFill,
    error: Color(0xFFB3261E),
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: ink,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 64,
      backgroundColor: Colors.white,
      indicatorColor: selectedFill,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ink,
          );
        }
        return const TextStyle(fontSize: 12, color: inkMuted);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected) ? ink : inkMuted,
        );
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: ink,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),
    dividerTheme: const DividerThemeData(
      color: border,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardFill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ink, width: 2),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: ink),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return ink;
        return null;
      }),
    ),
  );
}

/// Time-of-day greeting for home (PLAN-000006).
String homeGreetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
