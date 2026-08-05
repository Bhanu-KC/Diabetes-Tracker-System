/// Add/Edit Meal screen.
///
/// Reached from the Meal Tracker screen floating action button or when a
/// user taps an existing meal to edit it. Lets the user record what they
/// ate: meal name, meal type (breakfast/lunch/dinner/snacks), calories,
/// date and notes. Saves to the local FloorDB via the [MealRepository].
/// Passing [AddMealScreen.existing] switches the screen to edit mode.

library;

import 'package:flutter/material.dart';
import '../database/entities/meal_entity.dart';
import '../database/repositories/meal_repository.dart';
import '../theme/app_theme.dart';

/// Form screen to add a new meal or edit an existing one.
class AddMealScreen extends StatefulWidget {
  /// When provided, the form is prefilled and saving updates this record.
  final MealEntity? existing;

  const AddMealScreen({super.key, this.existing});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  /// Validates the form before saving.
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();

  /// Selected meal type from the dropdown.
  String _mealType = 'Breakfast';

  /// Date chosen by the user for the meal.
  DateTime _date = DateTime.now();

  /// Disables the button and shows a spinner while saving.
  bool _isSaving = false;

  /// Keeps the original timestamp when editing so the meal's logged
  /// date and time are preserved.
  int? _originalTimestamp;

  /// The meal types the user can choose from.
  final _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  /// True when this screen is editing an existing record.
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    // Prefill the form with the existing record's values when editing.
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      if (_mealTypes.contains(existing.mealType)) {
        _mealType = existing.mealType;
      }
      // Whole calorie values are shown without decimals (e.g. "450").
      final calories = existing.calories;
      if (calories != null) {
        _caloriesController.text = calories == calories.roundToDouble()
            ? calories.toInt().toString()
            : calories.toString();
      }
      _date = DateTime.fromMillisecondsSinceEpoch(existing.timestamp);
      _originalTimestamp = existing.timestamp;
      _notesController.text = existing.notes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Opens the system date picker and stores the chosen date.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// Saves the meal to the local database.
  ///
  /// Called when the save button is pressed. Inserts a new meal (or
  /// updates the existing one when editing), then shows a success/error
  /// snackbar and pops back to the previous screen.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      // Reuse the original timestamp when editing to keep the log order.
      final timestamp =
          _originalTimestamp ?? DateTime.now().millisecondsSinceEpoch;

      final repo = await MealRepository.getInstance();
      if (_isEditing) {
        await repo.update(
          MealEntity(
            id: widget.existing!.id,
            name: _nameController.text.trim(),
            mealType: _mealType,
            calories: double.parse(_caloriesController.text.trim()),
            timestamp: timestamp,
            notes: _notesController.text.trim(),
          ),
        );
      } else {
        await repo.add(
          MealEntity(
            name: _nameController.text.trim(),
            mealType: _mealType,
            calories: double.parse(_caloriesController.text.trim()),
            timestamp: timestamp,
            notes: _notesController.text.trim(),
          ),
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Meal updated successfully'
                : 'Meal added successfully',
          ),
          backgroundColor: AppColors.softGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save meal: $e'),
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
        title: Text(_isEditing ? 'Edit Meal' : 'Add Meal'),
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
              // Screen heading with the restaurant icon.
              Center(
                child: Column(
                  children: [
                    // Circular icon marking the meal section.
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        size: 38,
                        color: AppColors.softGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isEditing ? 'Update Meal' : 'Add Meal',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Record what you ate today',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.subtitleGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Name of the meal (e.g. Grilled chicken salad).
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Meal Name',
                  prefixIcon: Icon(Icons.restaurant),
                  hintText: 'e.g. Grilled chicken salad',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Meal name is required' : null,
              ),
              const SizedBox(height: 14),
              // Dropdown to choose which meal of the day this is.
              DropdownButtonFormField<String>(
                initialValue: _mealType,
                decoration: const InputDecoration(
                  labelText: 'Meal Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _mealTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _mealType = v ?? 'Breakfast'),
              ),
              const SizedBox(height: 14),
              // Numeric field for calories (must be a positive number).
              TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calories',
                  prefixIcon: Icon(Icons.local_fire_department),
                  suffixText: 'kcal',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Calories is required';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Tappable field that opens the date picker.
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text('${_date.day}/${_date.month}/${_date.year}'),
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
                          _isEditing ? 'Update Meal' : 'Save Meal',
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
