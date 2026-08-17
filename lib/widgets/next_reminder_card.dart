/// Card showing the single next upcoming reminder.
///
/// Shown at the top of the dashboard tab. Displays whether the reminder
/// is for medication or insulin and the time it will fire. When no
/// reminder exists (no records with reminders enabled) the message
/// "No upcoming reminders." is shown instead.

library;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The type of the next reminder as returned by the dashboard logic.
///
/// [type] is "Medication" or "Insulin", [name] is the record name and
/// [time] is the 12-hour time when the reminder fires.
typedef NextReminderInfo = ({String type, String name, String time});

/// Card that shows the next upcoming reminder (or an empty message).
class NextReminderCard extends StatelessWidget {
  /// The computed next reminder, or null when there is none.
  final NextReminderInfo? reminder;

  const NextReminderCard({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    final r = reminder;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon circle for the reminder type.
            CircleAvatar(
              backgroundColor: AppColors.lightBlue,
              radius: 22,
              child: Icon(
                r == null ? Icons.notifications_off_outlined : Icons.alarm,
                color: AppColors.primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Title and type/name text.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Reminder',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 14),
                  ),
                  Text(
                    r == null
                        ? 'No upcoming reminders.'
                        : '${r.type} ${r.name}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            // Pill showing the reminder time.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                r?.time ?? '--',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}