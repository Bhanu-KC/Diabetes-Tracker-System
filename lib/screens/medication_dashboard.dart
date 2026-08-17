// Medication dashboard screen showing all medications.


import 'dart:async';

import 'package:flutter/material.dart';
import 'medication_details.dart';
import '../database/entities/medication_entity.dart';
import '../database/repositories/medication_repository.dart';
import '../theme/app_theme.dart';

/// Lists and manages all medications.
class MedicationDashboard extends StatefulWidget {
  const MedicationDashboard({super.key});

  @override
  State<MedicationDashboard> createState() => _MedicationDashboardState();
}

class _MedicationDashboardState extends State<MedicationDashboard> {
  /// Live medication list, null while loading.
  List<MedicationEntity>? _medications;

  /// Load error shown instead of the list.
  String? _error;

  /// Medication stream subscription, cancelled in [dispose].
  StreamSubscription<List<MedicationEntity>>? _medicationsSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _medicationsSub?.cancel();
    super.dispose();
  }

  /// Starts listening to the live medication stream.
  Future<void> _init() async {
    try {
      final repo = await MedicationRepository.getInstance();
      if (!mounted) return;
      _medicationsSub = repo.watchAll().listen(
        (medications) {
          if (mounted) setState(() => _medications = medications);
        },
        onError: (e) {
          if (mounted) setState(() => _error = '$e');
        },
      );
    } catch (e) {
      // just in case, show the error instead of a blank screen
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final medications = _medications;
    return Scaffold(
      appBar: AppBar(title: const Text('Medications')),
      backgroundColor: AppColors.backgroundGrey,
      // Opens the Add Medication screen.
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-medication'),
        child: const Icon(Icons.add),
      ),
      // Error, loading, empty, or list state.
      body: _error != null
          ? _messageState(
              context,
              Icons.error_outline,
              _error!,
              backgroundColor: AppColors.errorRed,
            )
          : medications == null
          ? const Center(child: CircularProgressIndicator())
          : medications.isEmpty
          ? _messageState(
              context,
              Icons.medication_outlined,
              'No medications yet.\nTap + to add your first medication',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: medications.length,
              itemBuilder: (_, i) => _MedicationCard(
                medication: medications[i],
                color: _colorFor(i),
                icon: i.isEven ? Icons.medication : Icons.biotech,
                // Tap opens the details screen.
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MedicationDetails(medication: medications[i]),
                  ),
                ),
              ),
            ),
    );
  }

  /// Rotating accent colour, one per list position.
  Color _colorFor(int index) {
    const colors = [
      AppColors.primaryBlue,
      AppColors.softGreen,
      AppColors.warningAmber,
      AppColors.errorRed,
    ];
    return colors[index % colors.length];
  }

  /// Centered icon and message for error/empty states.
  Widget _messageState(
    BuildContext context,
    IconData icon,
    String message, {
    Color? backgroundColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.subtitleGrey),
            ),
          ],
        ),
      ),
    );
  }
}


/// One medication shown as a tappable card.
class _MedicationCard extends StatelessWidget {
  final MedicationEntity medication;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _MedicationCard({
    required this.medication,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  /// Converts "HH:mm" reminder time to 12-hour text.
  String get _reminderText {
    final parts = medication.reminderTime.split(':');
    if (parts.length != 2) return medication.reminderTime;
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Circular icon in a soft tint.
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                radius: 28,
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              // Name, dosage/frequency and reminder pill.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Dosage and frequency.
                    Text(
                      '${medication.dosage}  ${medication.frequency}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    // Pill showing the reminder time.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_active,
                            size: 14,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reminder: $_reminderText',
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron showing the card opens details.
              const Icon(Icons.chevron_right, color: AppColors.subtitleGrey),
            ],
          ),
        ),
      ),
    );
  }
}
