// A blood sugar (glucose) reading saved in the glucose_records table.

import 'package:floor/floor.dart';

/// One glucose reading row in the database.
@Entity(tableName: 'glucose_records')
class GlucoseEntity {
  /// Auto-generated database id (null until saved).
  @PrimaryKey(autoGenerate: true)
  final int? id;

  /// Blood sugar value in mg/dL.
  final double level;

  /// When it was taken: fasting, before or after a meal.
  final String mealContext;

  /// Optional note.
  final String notes;

  /// When the reading was taken (ms since epoch).
  final int timestamp;

  GlucoseEntity({
    this.id,
    required this.level,
    required this.mealContext,
    this.notes = '',
    required this.timestamp,
  });

  // Makes a copy of this reading so I can change just the id without
  // touching the rest of it (used after a new row is saved in the database).
  GlucoseEntity copyWith({int? id}) {
    return GlucoseEntity(
      id: id ?? this.id,
      level: level,
      mealContext: mealContext,
      notes: notes,
      timestamp: timestamp,
    );
  }
}
