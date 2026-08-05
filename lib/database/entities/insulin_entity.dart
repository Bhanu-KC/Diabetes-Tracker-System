/// Entity representing a single insulin dose logged by the user.
///
/// This model maps directly to the `insulin_records` table in the local
/// FloorDB database. It exists so insulin logs can be stored offline and
/// shown in the insulin screen list and as a reminder card on the home
/// dashboard.

library;

import 'package:floor/floor.dart';

/// A single insulin log entry stored in the `insulin_records` table.
///
/// When the user saves an insulin dose in the Add Insulin screen a new
/// [InsulinEntity] is created and written through the insulin DAO.
@Entity(tableName: 'insulin_records')
class InsulinEntity {
  /// Auto-generated primary key assigned by the database (null until saved).
  @PrimaryKey(autoGenerate: true)
  final int? id;

  /// Type name of the insulin, e.g. "Rapid-acting", "Long-acting".
  final String name;

  /// Number of units injected, e.g. 10 (can be a decimal).
  final double dose;

  /// Body site used for the injection, e.g. "Abdomen", "Thigh".
  final String site;

  /// Time of the injection in 24-hour format, e.g. "08:00".
  final String time;

  /// Whether a daily reminder notification is scheduled for this
  /// insulin record. Controlled by the "Reminder Enabled" switch in
  /// the Add Insulin screen.
  final bool reminderEnabled;

  /// Whether the reminder repeats every day. When false the reminder
  /// fires only once at the chosen time. Controlled by the
  /// "Repeat Daily" switch.
  final bool repeatDaily;

  /// Milliseconds since epoch when the dose was logged.
  /// Used to order records and calculate insulin used per day.
  final int timestamp;

  /// Optional note attached to the dose.
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
