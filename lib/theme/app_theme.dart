/// All colours and theme styles for the whole app live here.

library;

import 'package:flutter/material.dart';

/// The app's colour palette — all colours as constants.
class AppColors {
  /// Main brand blue (app bar, buttons).
  static const Color primaryBlue = Color(0xFF1565C0);

  /// Accent green (FABs, success).
  static const Color softGreen = Color(0xFF66BB6A);

  /// Light green background for healthy status cards.
  static const Color lightGreen = Color(0xFFE8F5E9);

  /// Light blue background for info cards.
  static const Color lightBlue = Color(0xFFE3F2FD);

  /// White for card backgrounds and surfaces.
  static const Color white = Colors.white;

  /// Light grey screen background.
  static const Color backgroundGrey = Color(0xFFF5F7FA);

  /// Dark grey for main text.
  static const Color darkText = Color(0xFF212121);

  /// Medium grey for secondary text.
  static const Color subtitleGrey = Color(0xFF757575);

  /// Red for errors and delete actions.
  static const Color errorRed = Color(0xFFE53935);

  /// Amber for high blood sugar warnings.
  static const Color warningAmber = Color(0xFFFFA726);
}

/// Builds the app-wide light theme.
class AppTheme {
  /// The light theme for the whole app.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // Colours come from the brand blue and green.
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        secondary: AppColors.softGreen,
        surface: AppColors.white,
        error: AppColors.errorRed,
      ),
      // Light grey background on every screen by default.
      scaffoldBackgroundColor: AppColors.backgroundGrey,
      // Blue app bar with a white title.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      // White rounded cards.
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // Blue filled buttons for main actions.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      // Blue outlined buttons for secondary actions.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.primaryBlue),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      // White text fields, rounded, blue when focused.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.subtitleGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.subtitleGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      // Green FAB for adding new records.
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.softGreen,
        foregroundColor: AppColors.white,
      ),
      // White nav bar, blue when selected.
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.subtitleGrey,
      ),
      // Font sizes and weights used everywhere.
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.darkText,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.darkText,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.darkText),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkText),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.subtitleGrey),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }
}
