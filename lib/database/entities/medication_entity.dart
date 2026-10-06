// A medication added by the user, saved in the medication_records table.

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

  /// Whether the user has marked this dose as taken.
  final bool taken;

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
    this.taken = false,
    required this.startDate,
    required this.endDate,
    this.notes = '',
  });

  // Makes a copy of this medication so I can change just the id (or the
  // taken flag) without touching the rest of it. Used after a new row is
  // saved in the database, and when the user checks the "taken" box.
  MedicationEntity copyWith({int? id, bool? taken}) {
    return MedicationEntity(
      id: id ?? this.id,
      name: name,
      dosage: dosage,
      frequency: frequency,
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
      repeatDaily: repeatDaily,
      taken: taken ?? this.taken,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
    );
  }
}
