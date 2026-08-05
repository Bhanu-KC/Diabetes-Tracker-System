library;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/notification_service.dart';

/// Called once when the application starts.
///
/// Waits for Firebase to be ready (using the generated platform options)
/// and then runs the app. This is an asynchronous function because
/// `Firebase.initializeApp` returns a Future that must complete first.
Future<void> main() async {
  // Ensures the Flutter engine is ready before awaiting Firebase.
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase with the options generated for the current platform.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Set up local notifications (timezone + plugin) before the UI loads.
  await NotificationService.instance.initializeNotifications();
  // Start the user interface with the root app widget.
  runApp(const DiabetesApp());

  // After the first frame is drawn, request notification permission
  // (once, on first launch). The denial message is shown via the root
  // navigator so it appears on top of the current screen.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      NotificationService.instance.handleFirstLaunchPermission(context);
    }
  });
}
