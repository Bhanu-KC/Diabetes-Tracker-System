/// Medication details screen.
///
/// Reached by tapping a medication card on the medication dashboard.
/// Shows all stored information about one medication (name, dosage,
/// frequency, reminder time, start/end dates and notes). Offers Edit
/// and Delete actions. Deletion is performed through the
/// [MedicationRepository] after a confirmation dialog.

library;

import 'package:flutter/material.dart';
import 'add_medication_screen.dart';
import '../database/entities/medication_entity.dart';
import '../database/repositories/medication_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Read-only details view for a single medication.
class MedicationDetails extends StatelessWidget {
  /// The medication to display. When null the screen shows a message.
  final MedicationEntity? medication;

  const MedicationDetails({super.key, this.medication});

  /// Formats a millisecond timestamp as "dd Mon yyyy" (e.g. "05 Aug 2026").
  String _formatDate(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final padded = d.day.toString().padLeft(2, '0');
    return '$padded ${months[d.month - 1]} ${d.year}';
  }

  /// Converts a stored "HH:mm" string into a 12-hour time (e.g. "2:30 PM").
  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return time;
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Asks the user to confirm, then deletes the medication.
  ///
  /// Shows an alert dialog first; only a confirmed delete removes the
  /// medication through the repository and pops back to the dashboard.
  Future<void> _delete(BuildContext context, MedicationEntity med) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Delete ${med.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final repo = await MedicationRepository.getInstance();
      await repo.delete(med);
      // Stop the scheduled reminder for the deleted medication.
      await NotificationService.instance.cancelNotification(
        NotificationService.medicationNotificationId(med.id!),
      );
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication deleted'),
          backgroundColor: AppColors.softGreen,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete medication: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final med = medication;
    return Scaffold(
      appBar: AppBar(title: const Text('Medication Details')),
      backgroundColor: AppColors.backgroundGrey,
      body: med == null
          ? Center(
              child: Text(
                'No medication selected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.subtitleGrey,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header card with the medication icon and name.
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medication,
                            size: 38,
                            color: AppColors.softGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Medication name.
                        Text(
                          med.name,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Dosage and frequency summary.
                        Text(
                          '${med.dosage}  ${med.frequency}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.subtitleGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Card listing every stored detail of the medication.
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medication Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // One labelled row per field.
                        _detailRow(
                          theme,
                          Icons.medication,
                          'Medicine Name',
                          med.name,
                        ),
                        const Divider(height: 20),
                        _detailRow(theme, Icons.science, 'Dosage', med.dosage),
                        const Divider(height: 20),
                        _detailRow(
                          theme,
                          Icons.repeat,
                          'Frequency',
                          med.frequency,
                        ),
                        const Divider(height: 20),
                        _detailRow(
                          theme,
                          Icons.access_time,
                          'Reminder Time',
                          _formatTime(med.reminderTime),
                        ),
                        const Divider(height: 20),
                        _detailRow(
                          theme,
                          Icons.alarm,
                          'Reminder',
                          med.reminderEnabled
                              ? (med.repeatDaily
                                    ? 'Enabled (daily)'
                                    : 'Enabled (once)')
                              : 'Disabled',
                        ),
                        const Divider(height: 20),
                        _detailRow(
                          theme,
                          Icons.calendar_today,
                          'Start Date',
                          _formatDate(med.startDate),
                        ),
                        const Divider(height: 20),
                        _detailRow(
                          theme,
                          Icons.event,
                          'End Date',
                          _formatDate(med.endDate),
                        ),
                        const Divider(height: 20),
                        _detailRow(
                          theme,
                          Icons.notes,
                          'Notes',
                          med.notes.isEmpty ? '-' : med.notes,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Edit and Delete buttons side by side.
                Row(
                  children: [
                    // Opens the Add Medication screen in edit mode.
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddMedicationScreen(existing: med),
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Deletes the medication after confirmation.
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _delete(context, med),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.errorRed,
                            side: const BorderSide(color: AppColors.errorRed),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  /// One labelled information row (icon, label and value).
  Widget _detailRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.subtitleGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.subtitleGrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
