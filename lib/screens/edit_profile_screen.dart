// Edit Profile screen.


import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

/// Form for editing the user's profile.
class EditProfileScreen extends StatefulWidget {
  /// The current profile used to prefill the form.
  final UserProfile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  /// Validates the form before saving.
  final _formKey = GlobalKey<FormState>();

  /// Controllers for all the editable fields.
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  /// Selected gender and diabetes type.
  String _gender = 'Male';
  String _diabetesType = 'Type 1';

  /// Shows a spinner while saving.
  bool _isLoading = false;
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  /// Options for the dropdowns.
  static const _genders = ['Male', 'Female', 'Other'];
  static const _diabetesTypes = [
    'Type 1',
    'Type 2',
    'Gestational',
    'Pre-diabetic',
  ];

  @override
  void initState() {
    super.initState();
    // Prefill the fields with the current values.
    final p = widget.profile;
    _nameController.text = p.fullName.trim();
    if (p.age != null) _ageController.text = p.age.toString();
    if (p.height != null) _heightController.text = p.height.toString();
    if (p.weight != null) _weightController.text = p.weight.toString();
    if (_genders.contains(p.gender)) _gender = p.gender!;
    if (_diabetesTypes.contains(p.diabetesType)) {
      _diabetesType = p.diabetesType!;
    }
    _emergencyNameController.text = p.emergencyContactName ?? '';
    _emergencyPhoneController.text = p.emergencyContactNumber ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }


  /// Saves the edited profile back to Firestore.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final uid = _authService.currentUser?.uid;
      if (uid == null) throw Exception('Not signed in');
      final p = widget.profile;
      await _firestoreService.updateUserProfile(
        UserProfile(
          uid: uid,
          fullName: _nameController.text.trim(),
          age: int.tryParse(_ageController.text),
          gender: _gender,
          height: double.tryParse(_heightController.text),
          weight: double.tryParse(_weightController.text),
          diabetesType: _diabetesType,
          // email can't be changed here, keep the old one
          email: p.email,
          emergencyContactName: _emergencyNameController.text.trim(),
          emergencyContactNumber: _emergencyPhoneController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved!'),
          backgroundColor: AppColors.softGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
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
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with an edit icon and description.
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 38,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Update Your Details',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your changes will be saved to your account',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.subtitleGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Personal details with validation.
              Text(
                'Personal Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildTextField(
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
                    child: _buildTextField(
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
                      items: _genders
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
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
                    child: _buildTextField(
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
                items: _diabetesTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _diabetesType = v ?? 'Type 1'),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 10),

              // Emergency contact details.
              Text(
                'Emergency Contact',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emergencyNameController,
                label: 'Emergency Contact Name',
                icon: Icons.contact_emergency_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Emergency contact name is required' : null,
              ),
              const SizedBox(height: 14),
              _buildTextField(
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

              const SizedBox(height: 28),

              // Save button with a loading spinner.
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Standard text field with a label and icon.
  Widget _buildTextField({
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
