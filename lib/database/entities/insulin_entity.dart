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

  /// Whether the user has marked this dose as taken.
  final bool taken;

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
    this.taken = false,
    required this.timestamp,
    this.notes = '',
  });

  // Makes a copy of this dose so I can change just the id (or the taken
  // flag) without touching the rest of it. Used after a new row is saved
  // in the database, and when the user checks the "taken" box.
  InsulinEntity copyWith({int? id, bool? taken}) {
    return InsulinEntity(
      id: id ?? this.id,
      name: name,
      dose: dose,
      site: site,
      time: time,
      reminderEnabled: reminderEnabled,
      repeatDaily: repeatDaily,
      taken: taken ?? this.taken,
      timestamp: timestamp,
      notes: notes,
    );
  }
}
