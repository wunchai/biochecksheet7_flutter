// lib/app_theme.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/app_config.dart'; // Import app_config for colors

// Function to create a MaterialColor from a single base Color.
MaterialColor createMaterialColor(Color color) {
  List<double> strengths = <double>[.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(color.alpha * strength).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, <int, Color>{
    50: color.withOpacity(0.1),
    100: color.withOpacity(0.2),
    200: color.withOpacity(0.3),
    300: color.withOpacity(0.4),
    400: color.withOpacity(0.5),
    500: color.withOpacity(0.6),
    600: color.withOpacity(0.7),
    700: color.withOpacity(0.8),
    800: color.withOpacity(0.9),
    900: color.withOpacity(1.0),
  });
}

// Define the main application theme data
ThemeData appTheme() {
  return ThemeData(
    primarySwatch: createMaterialColor(primaryThemeBlue),
    primaryColor: primaryThemeBlue,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: createMaterialColor(primaryThemeBlue),
      accentColor: accentThemeAmber,
      backgroundColor: scaffoldBackgroundLightGrey,
    ).copyWith(secondary: accentThemeAmber),
    scaffoldBackgroundColor: scaffoldBackgroundLightGrey,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryThemeBlue,
      foregroundColor: lightText,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryThemeBlue,
        foregroundColor: lightText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryThemeBlue,
        side: const BorderSide(color: primaryThemeBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryThemeBlue,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        borderSide: BorderSide(color: Colors.grey),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        borderSide: BorderSide(color: primaryThemeBlue, width: 2.0),
      ),
      labelStyle: const TextStyle(color: darkText),
      hintStyle: TextStyle(color: darkText.withOpacity(0.6)),
      errorStyle: const TextStyle(color: Colors.red),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: darkText),
      displayMedium: TextStyle(color: darkText),
      displaySmall: TextStyle(color: darkText),
      headlineLarge: TextStyle(color: darkText),
      headlineMedium: TextStyle(color: darkText),
      headlineSmall: TextStyle(color: darkText),
      titleLarge: TextStyle(color: darkText),
      titleMedium: TextStyle(color: darkText),
      titleSmall: TextStyle(color: darkText),
      bodyLarge: TextStyle(color: darkText),
      bodyMedium: TextStyle(color: darkText),
      bodySmall: TextStyle(color: darkText),
      labelLarge: TextStyle(color: darkText),
      labelMedium: TextStyle(color: darkText),
      labelSmall: TextStyle(color: darkText),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}