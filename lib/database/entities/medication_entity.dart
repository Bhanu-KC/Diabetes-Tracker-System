/// Entity representing a medication added by the user.
///
/// This model maps directly to the `medication_records` table in the local
/// FloorDB database. It exists so the user's routine medications can be
/// stored offline and shown in the medication dashboard list and as a
/// reminder card on the home dashboard.

library;

import 'package:floor/floor.dart';

/// A single medication entry stored in the `medication_records` table.
///
/// When the user saves a medication in the Add Medication screen a new
/// [MedicationEntity] is created and written through the medication DAO.
@Entity(tableName: 'medication_records')
class MedicationEntity {
  /// Auto-generated primary key assigned by the database (null until saved).
  @PrimaryKey(autoGenerate: true)
  final int? id;

  /// Name of the medication, e.g. "Metformin".
  final String name;

  /// Prescribed dosage, e.g. "500 mg", shown as text on the card.
  final String dosage;

  /// How often the medication is taken, e.g. "Once daily".
  final String frequency;

  /// Preferred reminder time in 24-hour format, e.g. "08:00".
  final String reminderTime;

  /// Whether a daily reminder notification is scheduled for this
  /// medication. Controlled by the "Reminder Enabled" switch in the
  /// Add Medication screen.
  final bool reminderEnabled;

  /// Whether the reminder repeats every day. When false the reminder
  /// fires only once at the chosen time. Controlled by the
  /// "Repeat Daily" switch.
  final bool repeatDaily;

  /// Day the medication course starts (milliseconds since epoch).
  final int startDate;

  /// Day the medication course ends (milliseconds since epoch).
  final int endDate;

  /// Optional note attached to the medication.
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
