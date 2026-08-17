// Add or edit a medication.


import 'package:flutter/material.dart';
import '../database/entities/medication_entity.dart';
import '../database/repositories/medication_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Form to add a new medication or edit an existing one.
class AddMedicationScreen extends StatefulWidget {
  /// Prefills the form and updates this record on save.
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

  /// Selected frequency.
  String _frequency = 'Once daily';

  /// Reminder time for taking the medication.
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  /// Whether a reminder is scheduled.
  bool _reminderEnabled = true;

  /// Whether the reminder repeats daily.
  bool _repeatDaily = true;

  /// Start and end dates of the course.
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  /// Shows a spinner while saving.
  bool _isSaving = false;

  /// True when editing an existing record.
  bool get _isEditing => widget.existing != null;

  /// Frequencies the user can pick from.
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
    // Prefill the form when editing.
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _dosageController.text = existing.dosage;
      if (_frequencies.contains(existing.frequency)) {
        _frequency = existing.frequency;
      }
      // Parse "HH:mm" back into a TimeOfDay.
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

  /// Opens the time picker.
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  /// Opens the date picker for the start or end date.
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
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    // Reject an end date that comes before the start date.
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
      // Convert dates to midnight timestamps.
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
      // Format the reminder time as "HH:mm".
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
      // Schedule the reminder, or cancel it when disabled.
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
                ? 'Medication updated!'
                : 'Medication added!',
          ),
          backgroundColor: AppColors.softGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
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
              // Heading with the medication icon.
              Center(
                child: Column(
                  children: [
                    // Icon marking the medication section.
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
              // How often the medicine is taken.
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
              // Opens the reminder time picker.
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
              // Turns this medication's reminder on or off.
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
                    // Whether the reminder repeats daily.
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
              // Start and end date pickers.
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
              // Optional notes field.
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
              // Save button with a loading spinner.
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
