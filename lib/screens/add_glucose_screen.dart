// Add or edit a blood sugar reading.


import 'package:flutter/material.dart';
import '../database/entities/glucose_entity.dart';
import '../database/repositories/glucose_repository.dart';
import '../theme/app_theme.dart';

/// Form to add a new blood sugar reading or edit an existing one.
class AddGlucoseScreen extends StatefulWidget {
  /// Prefills the form and updates this record on save.
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

  /// Selected reading type.
  String _readingType = 'Fasting';

  /// Chosen date and time for the reading.
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  /// Shows a spinner while saving.
  bool _isSaving = false;

  /// Reading types the user can pick from.
  final _types = ['Fasting', 'Before Meal', 'After Meal', 'Bedtime'];

  /// True when editing an existing record.
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    // Prefill the form when editing.
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


  /// Opens the date picker.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      // clamp to 2020, nobody needs older readings
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  /// Opens the time picker.
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  /// Saves the reading to the local database.
  Future<void> _save() async {
    // Stop if the form is invalid.
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      // Combine date and time into one timestamp.
      final timestamp = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ).millisecondsSinceEpoch;

      final repo = await GlucoseRepository.getInstance();
      if (_isEditing) {
        // Update the existing record.
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
        // Add a new reading.
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
      // Show a confirmation message.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Reading updated successfully' : 'Reading added successfully'),
          backgroundColor: AppColors.softGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Could not save: $e');
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
              // Heading with the blood type icon.
              Center(
                child: Column(
                  children: [
                    // Icon marking the blood sugar section.
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
              // Glucose value, validated 20-600.
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
              // Reading type as filter chips.
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
              const SizedBox(height: 16),
              // Date and time pickers.
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
              const SizedBox(height: 20),
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
