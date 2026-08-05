/// Root widget of the Diabetes Tracking System application.
///
/// This file builds the [MaterialApp] that configures the app-wide theme
/// and registers every named route. Screens are navigated to using
/// `Navigator.pushNamed(context, '/route-name')`.

library;

import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/add_glucose_screen.dart';
import 'screens/add_meal_screen.dart';
import 'screens/add_medication_screen.dart';
import 'screens/history_screen.dart';
import 'screens/insulin_screen.dart';
import 'screens/add_insulin_screen.dart';
import 'screens/meal_screen.dart';
import 'screens/medication_dashboard.dart';
import 'screens/reports_screen.dart';

/// Global navigator key used to reach the root navigator from anywhere.
///
/// Needed so the first-launch notification permission dialog (requested
/// from `main()`) can be shown on top of whatever screen is visible.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Top-level widget of the app.
///
/// It configures the application title, the light theme, and the route
/// table that tells Flutter which screen to show for each named route.
class DiabetesApp extends StatelessWidget {
  const DiabetesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diabetes Tracking System',
      // App-wide colour and typography theme (similar to a stylesheet).
      theme: AppTheme.lightTheme,
      // Hides the "DEBUG" banner shown in the corner.
      debugShowCheckedModeBanner: false,
      // Global key so code outside the widget tree (e.g. the first-launch
      // permission dialog in main.dart) can access the root navigator.
      navigatorKey: navigatorKey,
      // The splash screen is shown first when the app opens.
      initialRoute: '/',
      routes: {
        // Authentication screens.
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        // Main screens shown after login.
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/history': (context) => const HistoryScreen(),
        '/reports': (context) => const ReportsScreen(),
        // Blood sugar screens.
        '/add-glucose': (context) => const AddGlucoseScreen(),
        // Medication screens.
        '/medication': (context) => const MedicationDashboard(),
        '/add-medication': (context) => const AddMedicationScreen(),
        // Insulin screens.
        '/insulin': (context) => const InsulinScreen(),
        '/add-insulin': (context) => const AddInsulinScreen(),
        // Meal tracking screens.
        '/meal-tracker': (context) => const MealScreen(),
        '/add-meal': (context) => const AddMealScreen(),
      },
    );
  }
}
