/// Tappable shortcut card that navigates to a major feature.
///
/// Used on the dashboard tab for the "Quick Actions" section (Blood
/// Sugar, Medication, Insulin, Meals). Each card shows a feature icon
/// and a label, and calls [onTap] when tapped.

library;

import 'package:flutter/material.dart';

/// A small tappable card with an icon and a label.
class QuickActionCard extends StatelessWidget {
  /// Feature icon in its accent colour.
  final IconData icon;

  /// Shortcut label, e.g. "Blood Sugar".
  final String label;

  /// Accent colour of the icon.
  final Color color;

  /// Called when the card is tapped (usually navigates to a screen).
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              // Feature icon in its accent colour.
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              // Shortcut label.
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}