// Wraps Firebase Authentication so screens never call Firebase directly.

import 'package:firebase_auth/firebase_auth.dart';

/// Auth methods backed by Firebase Authentication.
class AuthService {
  /// Firebase Auth instance.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The signed-in user, or null when logged out.
  User? get currentUser => _auth.currentUser;

  /// Stream that updates when the user signs in or out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Creates a new account with email and password.
  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs in an existing user.
  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs the current user out.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Sends a password reset email.
  Future<void> forgotPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Updates the current user's password (throws if not signed in).
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    await user.updatePassword(newPassword);
  }
}

/// Turns a Firebase error into a friendly message the UI can show.
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
        // Unknown code, just show Firebase's own message.
        return error.message ?? 'An error occurred. Please try again.';
    }
  }
  // Other errors just show their details so the cause isn't hidden.
  return error.toString();
}
