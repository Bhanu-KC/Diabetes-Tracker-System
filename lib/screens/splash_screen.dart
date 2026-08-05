/// Splash screen shown briefly when the app starts.
///
/// This is the first screen of the app (initial route '/'). It shows the
/// app logo and name with a fade-in animation for about 3 seconds, then
/// redirects the user either to the Home screen (if already signed in) or
/// to the Login screen (if not). It exists to give the app a clean,
/// branded start and to decide the first destination after startup.

library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// The splash/loading screen displayed on app launch.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Controls the fade-in animation of the logo and text.
  late AnimationController _controller;

  /// The actual opacity animation driven by [_controller].
  late Animation<double> _fadeAnimation;

  /// The timer that decides the navigation after 3 seconds.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Set up and start the fade-in animation.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // After 3 seconds, check if a user is signed in and navigate.
    _timer = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      User? user;
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (_) {
        user = null;
      }
      // Signed-in users go to the home screen, others to login.
      Navigator.pushReplacementNamed(
        context,
        user != null ? '/home' : '/login',
      );
    });
  }

  @override
  void dispose() {
    // Cancel the pending timer to avoid navigating after dispose.
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Blue gradient background for the whole splash screen.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
          ),
        ),
        child: Center(
          // FadeTransition animates the logo block from transparent.
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular container with the app heart icon (logo).
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monitor_heart_outlined,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                // App name shown in large white bold text.
                Text(
                  'Diabetes Tracking\nSystem',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                // Small decorative line under the title.
                Container(
                  height: 2,
                  width: 60,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                // Tagline below the app name.
                Text(
                  'Track Your Health, Live Better',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
