/// Authentication service wrapping Firebase Authentication.
///
/// This class centralizes every Firebase Auth call (register, login,
/// logout, password reset and password change) so screens never talk to
/// Firebase directly. Screens using this service: Splash, Login, Register,
/// Forgot Password and Profile (change password).

library;

import 'package:firebase_auth/firebase_auth.dart';

/// Provides authentication methods backed by Firebase Authentication.
class AuthService {
  /// Firebase Auth instance used for all operations in this service.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The currently signed-in user, or null when logged out.
  User? get currentUser => _auth.currentUser;

  /// Stream that emits the user whenever the sign-in state changes.
  /// Can be used to react to login/logout events.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Creates a new account with the given email and password.
  ///
  /// Called by the Register screen when the user taps "Register".
  /// The email is trimmed; Firebase throws if the email is taken,
  /// the password is weak, etc.
  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs in an existing user with email and password.
  ///
  /// Called by the Login screen when the user taps "Login". Screens
  /// then navigate to the home screen on success.
  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs the current user out.
  ///
  /// Called from the Profile screen "Log out" button.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Sends a password reset email to the given address.
  ///
  /// Called by the Forgot Password screen. Firebase handles sending
  /// the email, no password change happens here.
  Future<void> forgotPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Updates the password of the currently signed-in user.
  ///
  /// Called from the Profile screen "Change password" dialog. Requires
  /// the user to be signed in, otherwise an Exception is thrown.
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    await user.updatePassword(newPassword);
  }
}

/// Converts a Firebase error into a human-friendly message.
///
/// Firebase throws [FirebaseAuthException]s with machine-readable codes
/// (e.g. "email-already-in-use"). This helper maps those codes to simple
/// sentences so the UI can show the message directly to the user.
String getFriendlyAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign in is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-recipient-email':
        return 'Please enter a valid email address.';
      default:
        // Fall back to the raw Firebase message for unexpected errors.
        return error.message ?? 'An error occurred. Please try again.';
    }
  }
  // Non-Firebase errors (e.g. Firestore permission denied) show the
  // exception details so real causes are not hidden.
  return error.toString();
}
