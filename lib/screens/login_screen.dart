// Login screen where existing users sign in.


import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Lets the user sign in with email and password.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Validates the login form before submitting.
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Firebase auth helper.
  late final AuthService _authService = AuthService();

  /// "Remember Me" checkbox value.
  bool _rememberMe = false;

  /// Shows a spinner while signing in.
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  /// Signs the user in and opens the home screen.
  Future<void> _login() async {
    // Stop if the form is invalid.
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      // Replace login so back can't return to it.
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      // TODO: maybe log this somewhere better later
      debugPrint('Login error: $e');
      // Show a friendly error message.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getFriendlyAuthError(e)),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            // Form with the login fields.
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo at the top.
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.monitor_heart,
                      size: 44,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Heading and subtitle.
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to continue tracking',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.subtitleGrey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Email field with format check.
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      // Simple email format check.
                      final emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      );
                      if (!emailRegex.hasMatch(v.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  // Hidden password field, submits on done.
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    // enter key submits too
                    onFieldSubmitted: (_) => _login(),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Password is required' : null,
                  ),
                  const SizedBox(height: 8),
                  // Remember Me and Forgot Password row.
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (val) =>
                            setState(() => _rememberMe = val ?? false),
                        activeColor: AppColors.primaryBlue,
                      ),
                      Text(
                        'Remember Me',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      // Opens the reset screen.
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: AppColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Login button with a loading spinner.
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Login', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Link to the register screen.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.subtitleGrey,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
