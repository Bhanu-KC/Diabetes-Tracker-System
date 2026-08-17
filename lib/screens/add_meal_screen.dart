// Add or edit a meal.


import 'package:flutter/material.dart';
import '../database/entities/meal_entity.dart';
import '../database/repositories/meal_repository.dart';
import '../theme/app_theme.dart';

/// Form to add a new meal or edit an existing one.
class AddMealScreen extends StatefulWidget {
  /// Prefills the form and updates this record on save.
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

  /// Selected meal type.
  String _mealType = 'Breakfast';

  /// Chosen date for the meal.
  DateTime _date = DateTime.now();

  /// Shows a spinner while saving.
  bool _isSaving = false;

  /// Keeps the original timestamp when editing.
  int? _originalTimestamp;

  /// Meal types the user can pick from.
  final _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  /// True when editing an existing record.
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    // Prefill the form when editing.
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      if (_mealTypes.contains(existing.mealType)) {
        _mealType = existing.mealType;
      }
      // Show whole calories without decimals.
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


  /// Opens the date picker.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      // meals from before 2020 aren't relevant
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// Saves the meal to the local database.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      // Keep the original timestamp when editing.
      final timestamp = _originalTimestamp ?? DateTime.now().millisecondsSinceEpoch;

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
          // Cancel without saving.
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
              // Heading with the restaurant icon.
              Center(
                child: Column(
                  children: [
                    // Icon marking the meal section.
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
              // Name of the meal.
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
              // Which meal of the day this is.
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
              // Calories, must be a positive number.
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
              const SizedBox(height: 16),
              // Opens the date picker.
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
              const SizedBox(height: 12),
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
