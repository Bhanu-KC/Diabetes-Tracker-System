/// Add/Edit Insulin screen.
///
/// Reached from the Insulin screen floating action button or when a user
/// taps an existing insulin record to edit it. Lets the user log an
/// insulin dose: name, dose in units, injection site, time and notes.
/// Saves to the local FloorDB via the [InsulinRepository]. Passing
/// [AddInsulinScreen.existing] switches the screen to edit mode.

library;

import 'package:flutter/material.dart';
import '../database/entities/insulin_entity.dart';
import '../database/repositories/insulin_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Form screen to add a new insulin dose or edit an existing one.
class AddInsulinScreen extends StatefulWidget {
  /// When provided, the form is prefilled and saving updates this record.
  final InsulinEntity? existing;

  const AddInsulinScreen({super.key, this.existing});

  @override
  State<AddInsulinScreen> createState() => _AddInsulinScreenState();
}

class _AddInsulinScreenState extends State<AddInsulinScreen> {
  /// Validates the form before saving.
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _notesController = TextEditingController();

  /// Selected injection site from the dropdown.
  String _site = 'Abdomen';

  /// Chosen injection time of day.
  TimeOfDay _time = TimeOfDay.now();

  /// Whether a reminder notification is scheduled for this insulin record.
  bool _reminderEnabled = true;

  /// Whether the reminder repeats every day (or fires only once).
  bool _repeatDaily = true;

  /// Disables the button and shows a spinner while saving.
  bool _isSaving = false;

  /// Keeps the original timestamp when editing so the record's clock
  /// time is preserved even though only the time of day is shown.
  int? _originalTimestamp;

  /// The injection sites the user can choose from.
  final _sites = ['Abdomen', 'Thigh', 'Arm', 'Buttock', 'Other'];

  /// True when this screen is editing an existing record.
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    // Prefill the form with the existing record's values when editing.
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      // Whole doses are shown without decimals (e.g. "10", not "10.0").
      _doseController.text = existing.dose == existing.dose.roundToDouble()
          ? existing.dose.toInt().toString()
          : existing.dose.toString();
      if (_sites.contains(existing.site)) _site = existing.site;
      // Parse the "HH:mm" string back into a TimeOfDay.
      final parts = existing.time.split(':');
      if (parts.length == 2) {
        _time = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
      _originalTimestamp = existing.timestamp;
      _reminderEnabled = existing.reminderEnabled;
      _repeatDaily = existing.repeatDaily;
      _notesController.text = existing.notes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Opens the system time picker and stores the chosen time.
  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  /// Saves the insulin record to the local database.
  ///
  /// Called when the save button is pressed. Formats the chosen time as
  /// "HH:mm", inserts a new record or updates the existing one, then
  /// shows a success/error snackbar and pops back.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      // Convert the TimeOfDay into a "HH:mm" string for storage.
      final time =
          '${_time.hour.toString().padLeft(2, '0')}:'
          '${_time.minute.toString().padLeft(2, '0')}';
      // Reuse the original timestamp when editing to keep the log order.
      final timestamp =
          _originalTimestamp ?? DateTime.now().millisecondsSinceEpoch;

      final repo = await InsulinRepository.getInstance();
      final int insulinId;
      if (_isEditing) {
        insulinId = widget.existing!.id!;
        await repo.update(
          InsulinEntity(
            id: insulinId,
            name: _nameController.text.trim(),
            dose: double.parse(_doseController.text.trim()),
            site: _site,
            time: time,
            reminderEnabled: _reminderEnabled,
            repeatDaily: _repeatDaily,
            timestamp: timestamp,
            notes: _notesController.text.trim(),
          ),
        );
      } else {
        insulinId = await repo.add(
          InsulinEntity(
            name: _nameController.text.trim(),
            dose: double.parse(_doseController.text.trim()),
            site: _site,
            time: time,
            reminderEnabled: _reminderEnabled,
            repeatDaily: _repeatDaily,
            timestamp: timestamp,
            notes: _notesController.text.trim(),
          ),
        );
      }
      // When reminders are enabled schedule (or reschedule) the daily
      // notification. When disabled, stop any previously scheduled one.
      if (_reminderEnabled) {
        await NotificationService.instance.scheduleInsulinReminder(
          insulinId,
          _nameController.text.trim(),
          time,
          repeatDaily: _repeatDaily,
        );
      } else {
        await NotificationService.instance.cancelNotification(
          NotificationService.insulinNotificationId(insulinId),
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Insulin record updated successfully'
                : 'Insulin record added successfully',
          ),
          backgroundColor: AppColors.softGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save insulin record: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      // Title changes between Add and Edit mode.
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Insulin' : 'Add Insulin'),
        actions: [
          // Cancel button that exits the form without saving.
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen heading with the insulin icon.
              Center(
                child: Column(
                  children: [
                    // Circular icon marking the insulin section.
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.biotech,
                        size: 38,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isEditing
                          ? 'Update Insulin Record'
                          : 'New Insulin Record',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter insulin injection details',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.subtitleGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Name of the insulin (e.g. Humalog, Lantus).
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Insulin Name',
                  prefixIcon: Icon(Icons.biotech),
                  hintText: 'e.g. Humalog, Lantus',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Insulin name is required' : null,
              ),
              const SizedBox(height: 14),
              // Numeric field for the dose in units (validated 1-100).
              TextFormField(
                controller: _doseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dose',
                  prefixIcon: Icon(Icons.science),
                  hintText: 'e.g. 10 units',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Dose is required';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0 || n > 100) {
                    return 'Enter a valid dose (1-100)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Dropdown to choose the body site for the injection.
              DropdownButtonFormField<String>(
                initialValue: _site,
                decoration: const InputDecoration(
                  labelText: 'Injection Site',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: _sites
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _site = v ?? 'Abdomen'),
              ),
              const SizedBox(height: 14),
              // Tappable field that opens the time picker.
              InkWell(
                onTap: _pickTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Injection Time',
                    prefixIcon: const Icon(Icons.access_time),
                    helperText: _reminderEnabled
                        ? 'Local notification will be scheduled at this time'
                        : 'Reminder is currently disabled',
                  ),
                  child: Text(_time.format(context)),
                ),
              ),
              const SizedBox(height: 8),
              // Master switch that turns this record's reminder on/off.
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.alarm_on,
                        color: AppColors.primaryBlue,
                      ),
                      title: const Text('Reminder Enabled'),
                      subtitle: const Text(
                        'Schedule a local notification for this insulin',
                      ),
                      value: _reminderEnabled,
                      onChanged: (v) => setState(() => _reminderEnabled = v),
                    ),
                    const Divider(height: 1),
                    // Whether the reminder repeats every day.
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.repeat,
                        color: AppColors.warningAmber,
                      ),
                      title: const Text('Repeat Daily'),
                      subtitle: const Text(
                        'Repeat the reminder every day at the same time',
                      ),
                      value: _repeatDaily,
                      onChanged: _reminderEnabled
                          ? (v) => setState(() => _repeatDaily = v)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Optional multi-line notes field.
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.notes),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Full-width save button with a loading spinner.
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing
                              ? 'Update Insulin Record'
                              : 'Save Insulin Record',
                          style: const TextStyle(fontSize: 16),
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
}
