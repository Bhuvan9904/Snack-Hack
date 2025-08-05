import 'package:flutter/material.dart';

/// All reusable colors used across the app
class AppColors {
  // Background
  static const Color background = Color(0xFF161825); // Screen background

  // Primary Colors
  static const Color primary = Color(0xFF3E4464); // AppBar, main UI elements
  static const Color secondary = Color(0xFF3B3C50); // Cards, tabs, etc.

  // Call-To-Action (CTA) Buttons
  static const Color primaryCTA = Color(0xFF3CC45B); // Green button (main)
  static const Color secondaryCTA = Color(
    0xFFF0BF44,
  ); // Yellow button (secondary)

  // Text Colors
  static const Color textLight = Colors.white; // Use on dark backgrounds
  static const Color textDark =
      Colors.black; // Use on light (yellow) backgrounds
}

/// Theme configuration for the app
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textLight,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textLight,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textLight, fontSize: 18),
      bodyMedium: TextStyle(color: AppColors.textLight, fontSize: 16),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryCTA,
        foregroundColor: AppColors.textLight,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
  );
}
