/// Central theme definitions for the Diabetes Tracking System.
///
/// This file keeps all colours and theme settings in one place so every
/// screen looks consistent. [AppColors] defines the colour palette used
/// throughout the app, and [AppTheme] builds the Material 3 light theme
/// (app bar, buttons, cards, text fields and typography).

library;

import 'package:flutter/material.dart';

/// Central colour palette of the application.
///
/// All colours used in the app are defined here as constants, so the
/// same blue, green and grey tones are reused consistently everywhere.
class AppColors {
  /// Main brand colour used for the app bar, buttons and highlights.
  static const Color primaryBlue = Color(0xFF1565C0);

  /// Accent colour used for floating action buttons and success areas.
  static const Color softGreen = Color(0xFF66BB6A);

  /// Very light green background used for healthy status cards.
  static const Color lightGreen = Color(0xFFE8F5E9);

  /// Very light blue background used for information cards.
  static const Color lightBlue = Color(0xFFE3F2FD);

  /// Plain white used for card backgrounds and surfaces.
  static const Color white = Colors.white;

  /// Light grey screen background for the whole app.
  static const Color backgroundGrey = Color(0xFFF5F7FA);

  /// Dark grey used for main body text.
  static const Color darkText = Color(0xFF212121);

  /// Medium grey used for secondary/helper text.
  static const Color subtitleGrey = Color(0xFF757575);

  /// Red used for errors, warnings and delete actions.
  static const Color errorRed = Color(0xFFE53935);

  /// Amber used for warning/high blood sugar highlights.
  static const Color warningAmber = Color(0xFFFFA726);
}

/// Builds the application-wide theme.
///
/// Exposes a single [lightTheme] getter which is passed to the
/// `MaterialApp` widget in `app.dart`. It styles common widgets
/// (app bar, buttons, text fields, cards, FABs and navigation bar)
/// so individual screens do not need to repeat the same styling.
class AppTheme {
  /// The light theme applied to the whole application.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // Colour scheme generated from the brand blue and green.
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        secondary: AppColors.softGreen,
        surface: AppColors.white,
        error: AppColors.errorRed,
      ),
      // Light grey background on every screen by default.
      scaffoldBackgroundColor: AppColors.backgroundGrey,
      // App bar styled with the brand blue and white title.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      // White rounded cards used for lists and info sections.
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // Blue filled buttons used for primary actions (e.g. Login).
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
      // Blue outlined buttons used for secondary actions.
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
      // White text fields with rounded borders and a blue focus border.
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
      // Green floating action button used to add new records.
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.softGreen,
        foregroundColor: AppColors.white,
      ),
      // White bottom navigation bar with blue selected items.
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.subtitleGrey,
      ),
      // Standard font sizes and weights used across all screens.
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
