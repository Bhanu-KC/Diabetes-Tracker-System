/// Profile screen showing the user's personal information.
///
/// Reached from the bottom navigation "Profile" tab. Loads the profile
/// document from Firestore and displays the user's details (name, age,
/// gender, height, weight, diabetes type, emergency contact). Also
/// offers Edit Profile, Change Password, About App and Logout actions.

library;

import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// The screen that displays and manages the user's profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  /// The loaded profile (null until fetched or when missing).
  UserProfile? _profile;

  /// Shows a spinner while the profile is being fetched.
  bool _isLoading = true;

  /// Shows the error state instead of the profile when set.
  String? _error;

  /// Current state of the three notification settings.
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadNotificationSettings();
  }

  /// Loads the saved notification settings from the service.
  ///
  /// Called once when the screen opens so the switches show the user's
  /// current choices instead of the default values.
  Future<void> _loadNotificationSettings() async {
    final service = NotificationService.instance;
    final enabled = await service.isEnabled();
    final sound = await service.isSoundEnabled();
    final vibration = await service.isVibrationEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _soundEnabled = sound;
      _vibrationEnabled = vibration;
    });
  }

  /// Updates the Enable Notifications switch and the service.
  ///
  /// When notifications are turned off every pending reminder is
  /// cancelled so nothing fires in the future. Turning them back on
  /// allows reminders to be scheduled again.
  Future<void> _setNotificationsEnabled(bool value) async {
    setState(() => _notificationsEnabled = value);
    await NotificationService.instance.setEnabled(value);
  }

  /// Loads the current user's profile from Firestore.
  ///
  /// Called when the screen opens and again after editing so the shown
  /// information is always up to date. Errors are stored in [_error].
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final uid = _authService.currentUser?.uid;
      if (uid == null) {
        setState(() => _error = 'Not signed in');
      } else {
        final profile = await _firestoreService.getUserProfile(uid);
        setState(() => _profile = profile);
      }
    } catch (e) {
      setState(() => _error = 'Could not load profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = _profile;
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || profile == null
          ? _errorState(theme)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar with initials and the user's name/email.
                Center(
                  child: Column(
                    children: [
                      // Circular avatar showing the user's initials.
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primaryBlue,
                        child: Text(
                          _initials(profile.fullName),
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Full name.
                      Text(
                        profile.fullName,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Email address.
                      Text(
                        _authService.currentUser?.email ?? profile.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.subtitleGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Card with all personal information fields.
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // One labelled row per profile field.
                        _infoRow(
                          theme,
                          Icons.person_outline,
                          'Full Name',
                          profile.fullName,
                        ),
                        const Divider(height: 16),
                        _infoRow(
                          theme,
                          Icons.numbers,
                          'Age',
                          '${profile.age ?? '-'} years',
                        ),
                        const Divider(height: 16),
                        _infoRow(
                          theme,
                          Icons.people_outlined,
                          'Gender',
                          profile.gender ?? '-',
                        ),
                        const Divider(height: 16),
                        _infoRow(
                          theme,
                          Icons.straighten,
                          'Height',
                          '${profile.height ?? '-'} cm',
                        ),
                        const Divider(height: 16),
                        _infoRow(
                          theme,
                          Icons.monitor_weight_outlined,
                          'Weight',
                          '${profile.weight ?? '-'} kg',
                        ),
                        const Divider(height: 16),
                        _infoRow(
                          theme,
                          Icons.medical_services_outlined,
                          'Diabetes Type',
                          profile.diabetesType ?? '-',
                        ),
                        const Divider(height: 16),
                        _infoRow(
                          theme,
                          Icons.contact_emergency_outlined,
                          'Emergency Contact',
                          profile.emergencyContactName == null &&
                                  profile.emergencyContactNumber == null
                              ? '-'
                              : '${profile.emergencyContactName ?? '-'}  '
                                    '${profile.emergencyContactNumber ?? '-'}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Card with the notification settings switches.
                Card(
                  child: Column(
                    children: [
                      // Turns all reminders on or off.
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        title: const Text('Enable Notifications'),
                        subtitle: const Text('Receive medication and '
                            'insulin reminders'),
                        value: _notificationsEnabled,
                        onChanged: _setNotificationsEnabled,
                      ),
                      const Divider(height: 1),
                      // Plays a sound when a reminder fires.
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.volume_up_outlined,
                          color: AppColors.softGreen,
                        ),
                        title: const Text('Notification Sound'),
                        value: _soundEnabled,
                        onChanged: (v) async {
                          setState(() => _soundEnabled = v);
                          await NotificationService.instance.setSoundEnabled(v);
                        },
                      ),
                      const Divider(height: 1),
                      // Vibrates when a reminder fires.
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.vibration,
                          color: AppColors.warningAmber,
                        ),
                        title: const Text('Vibration'),
                        value: _vibrationEnabled,
                        onChanged: (v) async {
                          setState(() => _vibrationEnabled = v);
                          await NotificationService.instance
                              .setVibrationEnabled(v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Card with the profile action options.
                Card(
                  child: Column(
                    children: [
                      // Opens the Edit Profile screen and reloads after.
                      ListTile(
                        leading: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        title: const Text('Edit Profile'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditProfileScreen(profile: profile),
                            ),
                          );
                          _loadProfile();
                        },
                      ),
                      const Divider(height: 1),
                      // Opens the change password dialog.
                      ListTile(
                        leading: const Icon(
                          Icons.lock_outlined,
                          color: AppColors.softGreen,
                        ),
                        title: const Text('Change Password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _changePasswordDialog(context),
                      ),
                      const Divider(height: 1),
                      // Opens the about dialog.
                      ListTile(
                        leading: const Icon(
                          Icons.info_outline,
                          color: AppColors.warningAmber,
                        ),
                        title: const Text('About App'),
                        subtitle: const Text('Version 1.0.0'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _aboutDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Logout button that signs the user out.
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _authService.logout();
                      if (!context.mounted) return;
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: const BorderSide(color: AppColors.errorRed),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  /// Error state shown when the profile could not be loaded.
  Widget _errorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error ?? 'No profile found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.subtitleGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Retry button that reloads the profile.
            OutlinedButton(onPressed: _loadProfile, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  /// Builds short initials from a full name (e.g. "Bhanu Pratap" -> "BP").
  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Opens the dialog that lets the user change their password.
  ///
  /// Contains new/confirm password fields with validation. On submit the
  /// password is updated with Firebase via [AuthService.changePassword].
  Future<void> _changePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    var isSaving = false;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          // Sends the new password to Firebase on submit.
          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() => isSaving = true);
            try {
              await _authService.changePassword(newPasswordController.text);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed successfully'),
                  backgroundColor: AppColors.softGreen,
                ),
              );
            } catch (e) {
              if (!dialogContext.mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text(getFriendlyAuthError(e)),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            } finally {
              if (dialogContext.mounted) {
                setDialogState(() => isSaving = false);
              }
            }
          }

          return AlertDialog(
            title: const Text('Change Password'),
            // Form with the new and confirm password fields.
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // New password field (min 6 characters).
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Password is required';
                      }
                      if (v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  // Confirmation field that must match the first one.
                  TextFormField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (v != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              // Cancel closes the dialog without saving.
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              // Spinner while saving, otherwise the Save button.
              isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: submit,
                      child: const Text('Save'),
                    ),
            ],
          );
        },
      ),
    );
  }

  /// Opens the About dialog with app information.
  Future<void> _aboutDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('About'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App logo in a round blue container.
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monitor_heart_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            // App name.
            Text(
              'Diabetes Tracking System',
              style: Theme.of(
                dialogContext,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // Version number.
            Text(
              'Version 1.0.0',
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            // Short project description.
            const Text(
              'A BCA final year project to help you track blood sugar, '
              'insulin, medication, and meals in one place.',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// One labelled information row (icon, label and value).
  Widget _infoRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.subtitleGrey),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.subtitleGrey,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
