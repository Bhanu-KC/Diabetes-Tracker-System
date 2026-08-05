/// Add/Edit Medication screen.
///
/// Reached from the Medication dashboard floating action button or when
/// a user taps the edit button on the medication details screen. Lets
/// the user add a routine medication with name, dosage, frequency,
/// reminder time, start/end dates and notes. Saves to the local FloorDB
/// via the [MedicationRepository]. Passing
/// [AddMedicationScreen.existing] switches the screen to edit mode.

library;

import 'package:flutter/material.dart';
import '../database/entities/medication_entity.dart';
import '../database/repositories/medication_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Form screen to add a new medication or edit an existing one.
class AddMedicationScreen extends StatefulWidget {
  /// When provided, the form is prefilled and saving updates this record.
  final MedicationEntity? existing;

  const AddMedicationScreen({super.key, this.existing});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  /// Validates the form before saving.
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  /// Selected frequency from the dropdown.
  String _frequency = 'Once daily';

  /// Reminder time chosen for taking the medication.
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  /// Whether a reminder notification is scheduled for this medication.
  bool _reminderEnabled = true;

  /// Whether the reminder repeats every day (or fires only once).
  bool _repeatDaily = true;

  /// Start and end dates of the medication course.
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  /// Disables the button and shows a spinner while saving.
  bool _isSaving = false;

  /// True when this screen is editing an existing record.
  bool get _isEditing => widget.existing != null;

  /// The frequencies the user can choose from.
  final _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Every morning',
    'Every night',
    'As needed',
    'Weekly',
  ];

  @override
  void initState() {
    super.initState();
    // Prefill the form with the existing record's values when editing.
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _dosageController.text = existing.dosage;
      if (_frequencies.contains(existing.frequency)) {
        _frequency = existing.frequency;
      }
      // Parse the "HH:mm" reminder string back into a TimeOfDay.
      final parts = existing.reminderTime.split(':');
      if (parts.length == 2) {
        _reminderTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
      _startDate = DateTime.fromMillisecondsSinceEpoch(existing.startDate);
      _endDate = DateTime.fromMillisecondsSinceEpoch(existing.endDate);
      _reminderEnabled = existing.reminderEnabled;
      _repeatDaily = existing.repeatDaily;
      _notesController.text = existing.notes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Opens the system time picker for the reminder time.
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  /// Opens the system date picker for the start or end date.
  ///
  /// [isStart] selects which date is being picked: true for the start
  /// date, false for the end date.
  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  /// Saves the medication to the local database.
  ///
  /// Called when the save button is pressed. Converts the start/end
  /// dates and reminder time into storable numbers/strings, inserts a
  /// new record (or updates the existing one when editing), then shows
  /// a success/error snackbar and pops back.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    // A course must never end before it starts - reject invalid dates
    // with a clear message instead of saving bad data.
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be before the start date'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      // Convert start/end dates to midnight timestamps (day precision).
      final startMillis = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
      ).millisecondsSinceEpoch;
      final endMillis = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
      ).millisecondsSinceEpoch;
      // Format the reminder time as "HH:mm" for storage.
      final reminderTime =
          '${_reminderTime.hour.toString().padLeft(2, '0')}:'
          '${_reminderTime.minute.toString().padLeft(2, '0')}';

      final repo = await MedicationRepository.getInstance();
      final int medicationId;
      if (_isEditing) {
        medicationId = widget.existing!.id!;
        await repo.update(
          MedicationEntity(
            id: medicationId,
            name: _nameController.text.trim(),
            dosage: _dosageController.text.trim(),
            frequency: _frequency,
            reminderTime: reminderTime,
            reminderEnabled: _reminderEnabled,
            repeatDaily: _repeatDaily,
            startDate: startMillis,
            endDate: endMillis,
            notes: _notesController.text.trim(),
          ),
        );
      } else {
        medicationId = await repo.add(
          MedicationEntity(
            name: _nameController.text.trim(),
            dosage: _dosageController.text.trim(),
            frequency: _frequency,
            reminderTime: reminderTime,
            reminderEnabled: _reminderEnabled,
            repeatDaily: _repeatDaily,
            startDate: startMillis,
            endDate: endMillis,
            notes: _notesController.text.trim(),
          ),
        );
      }
      // When reminders are enabled schedule (or reschedule) the daily
      // notification. When disabled, stop any previously scheduled one.
      if (_reminderEnabled) {
        await NotificationService.instance.scheduleMedicationReminder(
          medicationId,
          _nameController.text.trim(),
          reminderTime,
          endDate: DateTime.fromMillisecondsSinceEpoch(endMillis),
          repeatDaily: _repeatDaily,
        );
      } else {
        await NotificationService.instance.cancelNotification(
          NotificationService.medicationNotificationId(medicationId),
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Medication updated successfully'
                : 'Medication added successfully',
          ),
          backgroundColor: AppColors.softGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save medication: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Title changes between Add and Edit mode.
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medication' : 'Add Medication'),
      ),
      backgroundColor: AppColors.backgroundGrey,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen heading with the medication icon.
              Center(
                child: Column(
                  children: [
                    // Circular icon marking the medication section.
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medication,
                        size: 38,
                        color: AppColors.softGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isEditing ? 'Update Medication' : 'New Medication',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter medication details',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.subtitleGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Name of the medicine.
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Medicine name is required' : null,
              ),
              const SizedBox(height: 14),
              // Dosage as text (e.g. "500 mg", "10 units").
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  prefixIcon: Icon(Icons.science),
                  hintText: 'e.g. 500 mg, 10 units',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Dosage is required' : null,
              ),
              const SizedBox(height: 14),
              // Dropdown to choose how often the medicine is taken.
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: _frequencies
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _frequency = v ?? 'Once daily'),
              ),
              const SizedBox(height: 14),
              // Tappable field that opens the reminder time picker.
              InkWell(
                onTap: _pickTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Reminder Time',
                    prefixIcon: const Icon(Icons.access_time),
                    helperText: _reminderEnabled
                        ? 'Local notification will be scheduled at this time'
                        : 'Reminder is currently disabled',
                  ),
                  child: Text(_reminderTime.format(context)),
                ),
              ),
              const SizedBox(height: 8),
              // Master switch that turns this medication's reminder on/off.
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.alarm_on,
                        color: AppColors.softGreen,
                      ),
                      title: const Text('Reminder Enabled'),
                      subtitle: const Text(
                        'Schedule a local notification for this medication',
                      ),
                      value: _reminderEnabled,
                      onChanged: (v) =>
                          setState(() => _reminderEnabled = v),
                    ),
                    const Divider(height: 1),
                    // Whether the reminder repeats every day.
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.repeat,
                        color: AppColors.primaryBlue,
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
              // Start and end date pickers side by side.
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          prefixIcon: Icon(Icons.event),
                        ),
                        child: Text(
                          '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                        ),
                      ),
                    ),
                  ),
                ],
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
                          _isEditing ? 'Update Medication' : 'Save Medication',
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
