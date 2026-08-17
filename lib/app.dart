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

/// Lets code outside the widget tree (like main.dart) reach the navigator.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// The root widget — sets up the theme and all screen routes.
class DiabetesApp extends StatelessWidget {
  const DiabetesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diabetes Tracking System',
      // App-wide theme (like a stylesheet).
      theme: AppTheme.lightTheme,
      // Hides the "DEBUG" banner.
      debugShowCheckedModeBanner: false,
      // So code outside the widget tree can reach the root navigator.
      navigatorKey: navigatorKey,
      // The splash screen shows first when the app opens.
      initialRoute: '/',
      routes: {
        // Auth screens.
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        // Main screens (after login).
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
        // Meal screens.
        '/meal-tracker': (context) => const MealScreen(),
        '/add-meal': (context) => const AddMealScreen(),
      },
    );
  }
}
