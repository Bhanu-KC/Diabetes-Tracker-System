/// Entity representing a single blood sugar (glucose) reading.
///
/// This model maps directly to the `glucose_records` table in the local
/// FloorDB database. It exists so the app can store and read blood sugar
/// values offline as typed objects. It is used by the blood sugar screens
/// (dashboard, history, reports) and their DAOs/repository.

library;

import 'package:floor/floor.dart';

/// A single glucose reading stored in the `glucose_records` table.
///
/// When a user taps the "Add Blood Sugar" button a new [GlucoseEntity]
/// is created and saved through the DAO.
@Entity(tableName: 'glucose_records')
class GlucoseEntity {
  /// Auto-generated primary key assigned by the database (null until saved).
  @PrimaryKey(autoGenerate: true)
  final int? id;

  /// Blood sugar value in mg/dL. The main measured value of the record.
  final double level;

  /// When the reading was taken relative to food.
  /// One of: fasting, before meal, after meal.
  final String mealContext;

  /// Optional user note attached to the reading.
  final String notes;

  /// Milliseconds since epoch when the reading was recorded.
  /// Used for ordering records by date and for chart display.
  final int timestamp;

  GlucoseEntity({
    this.id,
    required this.level,
    required this.mealContext,
    this.notes = '',
    required this.timestamp,
  });
}
