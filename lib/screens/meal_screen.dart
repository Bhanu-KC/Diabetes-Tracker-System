/// Meal Tracker screen.
///
/// Reached from the home dashboard quick action or the `/meal-tracker`
/// route. Shows today's calorie progress against a 2000 kcal goal and
/// the user's meals grouped by meal type (Breakfast, Lunch, Dinner,
/// Snacks). Data comes live from the local FloorDB via the
/// [MealRepository] stream. Tapping a meal opens the edit form;
/// long-pressing asks to delete it.

library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'add_meal_screen.dart';
import '../database/entities/meal_entity.dart';
import '../database/repositories/meal_repository.dart';
import '../theme/app_theme.dart';

/// The meal tracker screen showing meals and calorie progress.
class MealScreen extends StatefulWidget {
  const MealScreen({super.key});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  /// Meal types used for grouping and the daily calorie goal.
  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
  static const _goal = 2000;

  /// The live meal list (null while loading).
  List<MealEntity>? _meals;

  /// Shows the load error instead of the list when set.
  String? _error;

  /// Subscription to the meal stream; cancelled in [dispose].
  StreamSubscription<List<MealEntity>>? _mealsSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _mealsSub?.cancel();
    super.dispose();
  }

  /// Starts listening to the live meal stream from FloorDB.
  ///
  /// Called once in [initState]. Every change in the database (add,
  /// update, delete) triggers a rebuild with the new list.
  Future<void> _init() async {
    try {
      final repo = await MealRepository.getInstance();
      if (!mounted) return;
      _mealsSub = repo.watchAll().listen(
        (meals) {
          if (mounted) setState(() => _meals = meals);
        },
        onError: (e) {
          if (mounted) setState(() => _error = '$e');
        },
      );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  /// Sums the calories of all meals logged today.
  ///
  /// Compares each meal's timestamp against today's start and end to
  /// count only meals recorded on the current day.
  int get _todayCalories {
    final meals = _meals ?? const [];
    final now = DateTime.now();
    final todayStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;
    final todayEnd = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ).millisecondsSinceEpoch;
    var total = 0.0;
    for (final m in meals) {
      if (m.timestamp >= todayStart && m.timestamp <= todayEnd) {
        total += m.calories ?? 0;
      }
    }
    return total.round();
  }

  /// Opens the Add Meal screen in edit mode for the given meal.
  Future<void> _openEdit(MealEntity meal) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddMealScreen(existing: meal)),
    );
  }

  /// Asks the user to confirm, then deletes the meal.
  ///
  /// Shows an alert dialog. Only if the user confirms is the meal
  /// removed through the repository.
  Future<void> _confirmDelete(MealEntity meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text('Delete ${meal.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final repo = await MealRepository.getInstance();
      await repo.delete(meal);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal deleted'),
          backgroundColor: AppColors.softGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete meal: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(title: const Text('Meal Tracker')),
      // Floating action button that opens the Add Meal screen.
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddMealScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(theme),
    );
  }

  /// Builds the body: error message, loading spinner, empty state or
  /// the meal list grouped by type.
  Widget _buildBody(ThemeData theme) {
    if (_error != null) {
      // Error state with the failure message.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.subtitleGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final meals = _meals;
    if (meals == null) {
      // Loading spinner while the first stream event arrives.
      return const Center(child: CircularProgressIndicator());
    }
    if (meals.isEmpty) {
      // Friendly empty state with instructions to add a meal.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant_outlined,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No meals recorded yet',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppColors.subtitleGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to record your first meal',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.subtitleGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // List of the calorie progress card followed by one section per
    // meal type that has at least one meal.
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _calorieProgress(theme, _todayCalories, _goal),
        const SizedBox(height: 20),
        for (final type in _mealTypes)
          if (meals.any((m) => m.mealType == type)) ...[
            _mealSection(
              theme,
              type,
              meals.where((m) => m.mealType == type).toList(),
            ),
            const SizedBox(height: 16),
          ],
        const SizedBox(height: 20),
      ],
    );
  }

  /// Card showing today's calories against the daily goal.
  ///
  /// Combines a circular progress ring, the remaining/over-goal text and
  /// a linear progress bar. Colour turns amber at 100% and red when over.
  Widget _calorieProgress(ThemeData theme, int consumed, int goal) {
    final percent = goal == 0 ? 0.0 : consumed / goal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Circular calorie ring with the amount in the middle.
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      percent > 1 ? AppColors.errorRed : AppColors.warningAmber,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$consumed',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('kcal', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Summary text and linear bar on the right side.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Calories",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$consumed / $goal kcal consumed',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percent.clamp(0, 1),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      percent > 1 ? AppColors.errorRed : AppColors.warningAmber,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  // Remaining kcals or "over goal" message.
                  Text(
                    percent > 1
                        ? '${(consumed - goal)} kcal over goal'
                        : '${goal - consumed} kcal remaining',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: percent > 1
                          ? AppColors.errorRed
                          : AppColors.softGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds one meal group card (e.g. Breakfast) with its meals.
  ///
  /// Each meal row shows a colour accent, the name, a formatted time
  /// and its calories. Tap edits, long press deletes.
  Widget _mealSection(ThemeData theme, String title, List<MealEntity> items) {
    // Each meal type has its own icon and accent colour.
    final (icon, color) = switch (title) {
      'Breakfast' => (Icons.wb_sunny_outlined, AppColors.warningAmber),
      'Lunch' => (Icons.wb_cloudy_outlined, AppColors.primaryBlue),
      'Dinner' => (Icons.nightlight_outlined, AppColors.softGreen),
      _ => (Icons.cookie_outlined, AppColors.errorRed),
    };
    // Sum of all calories in this section.
    final sectionCalories = items.fold<int>(
      0,
      (sum, m) => sum + (m.calories?.round() ?? 0),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header: icon, title and total calories.
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$sectionCalories kcal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // One interactive row per meal in the section.
            ...items.map(
              (meal) => InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _openEdit(meal),
                onLongPress: () => _confirmDelete(meal),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // Colour accent bar on the left of the row.
                      Container(
                        width: 4,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Meal name.
                            Text(
                              meal.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // Time the meal was logged.
                            Text(
                              _formatTime(meal.timestamp),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      // Calories shown on the right.
                      Text(
                        '${meal.calories?.round() ?? 0} kcal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a millisecond timestamp as a 12-hour time (e.g. "2:30 PM").
  String _formatTime(int millis) {
    final t = DateTime.fromMillisecondsSinceEpoch(millis);
    final period = t.hour >= 12 ? 'PM' : 'AM';
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$hour:${t.minute.toString().padLeft(2, '0')} $period';
  }
}
