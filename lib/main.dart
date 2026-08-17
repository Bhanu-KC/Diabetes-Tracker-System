import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/notification_service.dart';

/// Runs when the app starts — sets up Firebase, then opens the app.
Future<void> main() async {
  // Get Flutter ready before using Firebase.
  WidgetsFlutterBinding.ensureInitialized();
  // Start Firebase with the options for this platform.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Set up notifications before showing the UI.
  await NotificationService.instance.initializeNotifications();
  // Open the app.
  runApp(const DiabetesApp());

  // After the first frame, ask for notification permission once.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      NotificationService.instance.handleFirstLaunchPermission(context);
    }
  });
}

