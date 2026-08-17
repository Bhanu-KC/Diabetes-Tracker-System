/// One item of the bottom navigation bar (icon + label).

library;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One tappable item of the bottom navigation bar.
class NavItem extends StatelessWidget {
  /// The icon (filled or outlined — the caller picks).
  final IconData icon;

  /// The short label under the icon, e.g. "Home".
  final String label;

  /// True when this tab is currently selected.
  final bool isSelected;

  /// Called when the user taps the item to switch tabs.
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The selected tab uses a filled icon in the brand colour.
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryBlue
                  : AppColors.subtitleGrey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.subtitleGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}