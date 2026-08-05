/// Entity representing a meal logged by the user.
///
/// This model maps directly to the `meal_records` table in the local
/// FloorDB database. It exists so meals can be stored offline and shown
/// in the meal tracker (grouped by Breakfast/Lunch/Dinner/Snacks) and in
/// the daily calorie summary on the dashboard.

library;

import 'package:floor/floor.dart';

/// A single meal entry stored in the `meal_records` table.
///
/// When the user saves a meal in the Add Meal screen a new [MealEntity]
/// is created and written through the meal DAO.
@Entity(tableName: 'meal_records')
class MealEntity {
  /// Auto-generated primary key assigned by the database (null until saved).
  @PrimaryKey(autoGenerate: true)
  final int? id;

  /// Name of the meal, e.g. "Oats", "Chicken salad".
  final String name;

  /// Which part of the day the meal belongs to.
  /// One of: Breakfast, Lunch, Dinner, Snacks. Used to group meals.
  final String mealType;

  /// Estimated carbohydrates in grams (optional).
  final double? carbs;

  /// Estimated calories for the meal (optional).
  /// Used to calculate the daily calorie total on the dashboard.
  final double? calories;

  /// Milliseconds since epoch when the meal was logged.
  /// Used to filter meals for the current day and to sort them.
  final int timestamp;

  /// Optional user note attached to the meal.
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
