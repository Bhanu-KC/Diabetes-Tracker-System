/// Widget tests for the Diabetes Tracking System app.
///
/// Smoke tests that boot the whole app and check the right screen shows up.
/// The login screen depends on Firebase (via the auth service), but Firebase
/// is initialized inside `main()` (closure), so `pumpWidget` can run this
/// test without real Firebase credentials.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:diabetes_tracking_system/app.dart';

void main() {
  // Smoke test: the app starts straight on the login screen.
  testWidgets('App loads and shows login', (WidgetTester tester) async {
    // Mount the root widget of the app.
    await tester.pumpWidget(const DiabetesApp());

    // The login screen must be visible right away.
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}