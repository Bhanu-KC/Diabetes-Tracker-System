// Shows the next upcoming reminder (or a "no reminders" message).


import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Holds the next reminder info: type, name and time.
class NextReminderInfo {
  final String type;
  final String name;
  final String time;

  NextReminderInfo(this.type, this.name, this.time);
}

/// Card showing the next upcoming reminder (or an empty message).
class NextReminderCard extends StatelessWidget {
  /// The next reminder, or null if there is none.
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
            // Title and reminder info.
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
