// A reminder card (green for medication, blue for insulin).


import 'package:flutter/material.dart';

/// One reminder row: icon, title, subtitle, and a time pill.
class ReminderCard extends StatelessWidget {
  /// Icon in the circle on the left.
  final IconData icon;

  /// Title text, e.g. "Medication".
  final String title;

  /// Short description, e.g. "Metformin 500 mg".
  final String subtitle;

  /// Time shown in the pill, e.g. "8:00 AM".
  final String time;

  /// Accent colour (icon, pill and text).
  final Color color;

  const ReminderCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon circle for the reminder type.
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 22,
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            // Title and subtitle.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 14),
                  ),
                  Text(
                    subtitle,
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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
