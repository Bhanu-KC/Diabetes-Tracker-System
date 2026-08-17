/// A medication added by the user, saved in the medication_records table.
library;

import 'package:floor/floor.dart';

/// One medication row in the database.
@Entity(tableName: 'medication_records')
class MedicationEntity {
  /// Auto-generated database id (null until saved).
  @PrimaryKey(autoGenerate: true)
  final int? id;

  /// Medication name, e.g. "Metformin".
  final String name;

  /// Dosage, e.g. "500 mg".
  final String dosage;

  /// How often it's taken, e.g. "Once daily".
  final String frequency;

  /// Reminder time in 24-hour format, e.g. "08:00".
  final String reminderTime;

  /// Whether a daily reminder is scheduled for this med.
  final bool reminderEnabled;

  /// Whether the reminder repeats every day (or fires once).
  final bool repeatDaily;

  /// Course start day (milliseconds since epoch).
  final int startDate;

  /// Course end day (milliseconds since epoch).
  final int endDate;

  /// Optional note.
  final String notes;

  MedicationEntity({
    this.id,
    required this.name,
    required this.dosage,
    this.frequency = 'Once daily',
    this.reminderTime = '08:00',
    this.reminderEnabled = true,
    this.repeatDaily = true,
    required this.startDate,
    required this.endDate,
    this.notes = '',
  });
}
