/// A card with one big highlighted number (like today's blood sugar).

library;

import 'package:flutter/material.dart';

/// A small card with an icon, a label and a large value with a unit.
class HighlightCard extends StatelessWidget {
  /// Icon in the round box at the top.
  final IconData icon;

  /// Short label, e.g. "Today's Blood Sugar".
  final String label;

  /// The big number shown, e.g. "120" (or "--" when empty).
  final String value;

  /// Unit shown next to the value, e.g. "mg/dL".
  final String unit;

  /// Accent colour for the value and icon.
  final Color color;

  /// Light background colour of the icon circle.
  final Color bgColor;

  const HighlightCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rounded icon box at the top of the card.
            CircleAvatar(
              backgroundColor: bgColor,
              radius: 20,
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            // Label text.
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            // Big number with its unit next to it.
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}