/// Widget tests for the Diabetes Tracking System app.
///
/// These smoke tests boot the whole app and check that the correct screen
/// appears. Note: the welcome screen depends on Firebase (via the splash
/// screen), but Firebase is initialized inside `main()` (closure) so
/// `pumpWidget` can run this test without real Firebase credentials.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:diabetes_tracking_system/app.dart';

void main() {
  // Smoke test: the app starts on the splash screen, shows its branding for
  // a few seconds, then automatically navigates to the login screen.
  testWidgets('App loads and navigates to login', (WidgetTester tester) async {
    // Mount the root widget of the app.
    await tester.pumpWidget(const DiabetesApp());

    // The splash screen should already show the app title.
    expect(find.textContaining('Diabetes Tracking'), findsOneWidget);

    // Fast-forward past the splash timer so its navigation completes.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // After the splash delay the login screen ('Welcome Back') must be shown.
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
