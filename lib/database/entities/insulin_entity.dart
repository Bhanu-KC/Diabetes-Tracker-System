// An insulin dose logged by the user, saved in the insulin_records table.

import 'package:floor/floor.dart';

/// One insulin log row in the database.
@Entity(tableName: 'insulin_records')
class InsulinEntity {
  /// Auto-generated database id (null until saved).
  @PrimaryKey(autoGenerate: true)
  final int? id;

  /// Insulin type, e.g. "Rapid-acting".
  final String name;

  /// Units injected, e.g. 10.
  final double dose;

  /// Injection site, e.g. "Abdomen".
  final String site;

  /// Injection time in 24-hour format, e.g. "08:00".
  final String time;

  /// Whether a daily reminder is scheduled for this dose.
  final bool reminderEnabled;

  /// Whether the reminder repeats every day (or fires once).
  final bool repeatDaily;

  /// When the dose was logged (ms since epoch).
  final int timestamp;

  /// Optional note.
  final String notes;

  InsulinEntity({
    this.id,
    required this.name,
    required this.dose,
    this.site = 'Abdomen',
    this.time = '08:00',
    this.reminderEnabled = true,
    this.repeatDaily = true,
    required this.timestamp,
    this.notes = '',
  });
}
