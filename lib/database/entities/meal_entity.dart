// A meal logged by the user, saved in the meal_records table.

import 'package:floor/floor.dart';

/// One meal row in the database.
@Entity(tableName: 'meal_records')
class MealEntity {
  /// Auto-generated database id (null until saved).
  @PrimaryKey(autoGenerate: true)
  final int? id;

  /// Meal name, e.g. "Oats".
  final String name;

  /// Which meal of the day it is (Breakfast, Lunch, Dinner, Snacks).
  final String mealType;

  /// Carbs in grams (optional).
  final double? carbs;

  /// Calories for the meal (optional).
  final double? calories;

  /// When the meal was logged (ms since epoch).
  final int timestamp;

  /// Optional note.
  final String notes;

  MealEntity({
    this.id,
    required this.name,
    this.mealType = 'Breakfast',
    this.carbs,
    this.calories,
    required this.timestamp,
    this.notes = '',
  });
}
