/// Add/Edit Blood Sugar screen.
///
/// Reached from the dashboard quick actions or the history screen. Lets
/// the user enter a glucose value, choose the reading type (fasting,
/// before/after meal, bedtime), pick a date and time, and save it to the
/// local FloorDB via the [GlucoseRepository]. The same screen is reused
/// for editing by passing an optional [AddGlucoseScreen.existing] record.

library;

import 'package:flutter/material.dart';
import '../database/entities/glucose_entity.dart';
import '../database/repositories/glucose_repository.dart';
import '../theme/app_theme.dart';

/// Form screen to add a new blood sugar reading or edit an existing one.
class AddGlucoseScreen extends StatefulWidget {
  /// When provided, the form is prefilled and saving updates this record
  /// instead of creating a new one.
  final GlucoseEntity? existing;

  const AddGlucoseScreen({super.key, this.existing});

  @override
  State<AddGlucoseScreen> createState() => _AddGlucoseScreenState();
}

class _AddGlucoseScreenState extends State<AddGlucoseScreen> {
  /// Validates the form before saving.
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();

  /// Selected reading type from the filter chips.
  String _readingType = 'Fasting';

  /// Date and time chosen by the user for the reading.
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  /// Disables the button and shows a spinner while saving.
  bool _isSaving = false;

  /// The reading types the user can choose from.
  final _types = ['Fasting', 'Before Meal', 'After Meal', 'Bedtime'];

  /// True when this screen is editing an existing record.
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    // Prefill the form with the existing record's values when editing.
    final existing = widget.existing;
    if (existing != null) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(existing.timestamp);
      _valueController.text = existing.level.toStringAsFixed(0);
      _notesController.text = existing.notes;
      if (_types.contains(existing.mealContext)) {
        _readingType = existing.mealContext;
      }
      _selectedDate = dateTime;
      _selectedTime = TimeOfDay.fromDateTime(dateTime);
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Opens the system date picker and stores the chosen date.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  /// Opens the system time picker and stores the chosen time.
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  /// Saves the reading to the local database.
  ///
  /// Called when the save button is pressed. Combines the selected date
  /// and time into a timestamp, then inserts a new record (or updates the
  /// existing one when editing). Shows a success/error snackbar and pops
  /// back to the previous screen.
  Future<void> _save() async {
    // Stop here if the form fields do not pass validation.
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      // Combine the picked date and time into a single timestamp.
      final timestamp = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ).millisecondsSinceEpoch;

      final repo = await GlucoseRepository.getInstance();
      if (_isEditing) {
        // Update the existing record, keeping its id.
        await repo.update(
          GlucoseEntity(
            id: widget.existing!.id,
            level: double.parse(_valueController.text),
            mealContext: _readingType,
            notes: _notesController.text.trim(),
            timestamp: timestamp,
          ),
        );
      } else {
        // Insert a brand new reading.
        await repo.add(
          GlucoseEntity(
            level: double.parse(_valueController.text),
            mealContext: _readingType,
            notes: _notesController.text.trim(),
            timestamp: timestamp,
          ),
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      // Confirm the save to the user.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Reading updated successfully'
                : 'Reading added successfully',
          ),
          backgroundColor: AppColors.softGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save reading: $e'),
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
      // Title changes between Add and Edit mode.
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Blood Sugar' : 'Add Blood Sugar'),
      ),
      backgroundColor: AppColors.backgroundGrey,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen heading with the blood type icon.
              Center(
                child: Column(
                  children: [
                    // Circular icon marking the blood sugar section.
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bloodtype,
                        size: 38,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isEditing ? 'Update Reading' : 'New Reading',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter your blood glucose details',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.subtitleGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Numeric field for the glucose value (validated 20-600).
              TextFormField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Blood Glucose Value (mg/dL)',
                  prefixIcon: Icon(Icons.bloodtype),
                  suffixText: 'mg/dL',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Value is required';
                  final n = double.tryParse(v);
                  if (n == null || n < 20 || n > 600) {
                    return 'Enter a valid reading (20-600)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              // Reading type selector (filter chips).
              Text('Reading Type', style: theme.textTheme.titleLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: _types.map((type) {
                  final selected = _readingType == type;
                  return FilterChip(
                    label: Text(type),
                    selected: selected,
                    onSelected: (_) => setState(() => _readingType = type),
                    selectedColor: AppColors.lightBlue,
                    checkmarkColor: AppColors.primaryBlue,
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              // Date and time pickers side by side.
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                          _isEditing ? 'Update Reading' : 'Save Reading',
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
