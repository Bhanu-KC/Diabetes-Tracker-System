/// Registration screen for creating a new user account.
///
/// Reached from the Login screen. The user fills in personal details,
/// an emergency contact and account credentials. On submit the account
/// is created with Firebase Authentication and the profile is saved to
/// Firestore. Registration signs the user in automatically, so the app
/// goes straight to the home dashboard.

library;

import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

/// The screen that creates a new account and user profile.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  /// Validates all form fields before registration is attempted.
  final _formKey = GlobalKey<FormState>();

  /// Controllers for every text field on the form.
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  /// Selected values for the gender and diabetes type dropdowns.
  String _gender = 'Male';
  String _diabetesType = 'Type 1';

  /// Controls whether the password fields show or hide their text.
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  /// Disables the button and shows a spinner while registering.
  bool _isLoading = false;
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Registers a new account and saves the profile in Firestore.
  ///
  /// Called when the Register button is pressed. First validates the
  /// form, then creates the Firebase account, then stores the user's
  /// details in the `users` collection. Account creation signs the user
  /// in automatically, so on success the app opens the home dashboard;
  /// failures show friendly error messages.
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Step 1: create the account with email and password.
        await _authService.register(
          email: _emailController.text,
          password: _passwordController.text,
        );
        // Step 2: store the profile details under the new user's UID.
        final user = _authService.currentUser;
        if (user != null) {
          await _firestoreService.createUserProfile(
            UserProfile(
              uid: user.uid,
              fullName: _nameController.text.trim(),
              age: int.tryParse(_ageController.text),
              gender: _gender,
              height: double.tryParse(_heightController.text),
              weight: double.tryParse(_weightController.text),
              diabetesType: _diabetesType,
              email: _emailController.text.trim(),
              emergencyContactName: _emergencyNameController.text.trim(),
              emergencyContactNumber: _emergencyPhoneController.text.trim(),
            ),
          );
        }
        if (!mounted) return;
        // Account created and profile saved: the user is already signed
        // in by Firebase, so go straight to the home dashboard.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: AppColors.softGreen,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        if (!mounted) return;
        // Show a friendly message (e.g. "email already in use").
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    // Circular app icon at the top of the form.
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1,
                        size: 38,
                        color: AppColors.softGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create Your Account',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fill in your details to get started',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.subtitleGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Personal Details
              sectionTitle(context, 'Personal Details'),
              const SizedBox(height: 12),
              buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Full name is required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Age is required';
                        final age = int.tryParse(v);
                        if (age == null || age < 1 || age > 150) {
                          return 'Enter valid age';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.people_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: buildTextField(
                      controller: _heightController,
                      label: 'Height (cm)',
                      icon: Icons.straighten,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Height is required';
                        final h = double.tryParse(v);
                        if (h == null || h < 50 || h > 300) {
                          return 'Enter valid height';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: buildTextField(
                      controller: _weightController,
                      label: 'Weight (kg)',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Weight is required';
                        final w = double.tryParse(v);
                        if (w == null || w < 10 || w > 500) {
                          return 'Enter valid weight';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _diabetesType,
                decoration: const InputDecoration(
                  labelText: 'Diabetes Type',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Type 1', child: Text('Type 1')),
                  DropdownMenuItem(value: 'Type 2', child: Text('Type 2')),
                  DropdownMenuItem(
                    value: 'Gestational',
                    child: Text('Gestational'),
                  ),
                  DropdownMenuItem(
                    value: 'Pre-diabetic',
                    child: Text('Pre-diabetic'),
                  ),
                ],
                onChanged: (v) => setState(() => _diabetesType = v ?? 'Type 1'),
              ),

              const SizedBox(height: 24),
              const Divider(),

              // Emergency Contact
              const SizedBox(height: 12),
              sectionTitle(context, 'Emergency Contact'),
              const SizedBox(height: 12),
              buildTextField(
                controller: _emergencyNameController,
                label: 'Emergency Contact Name',
                icon: Icons.contact_emergency_outlined,
                validator: (v) => v == null || v.isEmpty
                    ? 'Emergency contact name is required'
                    : null,
              ),
              const SizedBox(height: 14),
              buildTextField(
                controller: _emergencyPhoneController,
                label: 'Emergency Contact Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Phone number is required';
                  }
                  final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
                  if (digitsOnly.length < 10) {
                    return 'Enter valid 10-digit phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              const Divider(),

              // Account Security
              const SizedBox(height: 12),
              sectionTitle(context, 'Account Security'),
              const SizedBox(height: 12),
              buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  final emailRegex = RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                  );
                  if (!emailRegex.hasMatch(v)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              buildTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outlined,
                obscureText: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                icon: Icons.lock_outlined,
                obscureText: _obscureConfirm,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (v != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),
              // Full-width register button with a loading spinner.
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Register', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.subtitleGrey,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the heading text used for each section of the form.
  Widget sectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  /// Reusable styled text field used by all form inputs.
  ///
  /// Wraps [TextFormField] with a label and icon so the form code stays
  /// short and consistent. [validator] is used for field validation.
  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      ),
    );
  }
}
