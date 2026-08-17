/// Dashboard tab showing the user's health summary at a glance.
///
/// Displays the latest blood sugar, today's calorie total, medication
/// and insulin reminders, quick action shortcuts and a blood sugar
/// trend chart. All data is live: the tab subscribes to the four
/// FloorDB streams and rebuilds automatically when records change.

library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/entities/glucose_entity.dart';
import '../database/entities/insulin_entity.dart';
import '../database/entities/meal_entity.dart';
import '../database/entities/medication_entity.dart';
import '../database/repositories/glucose_repository.dart';
import '../database/repositories/insulin_repository.dart';
import '../database/repositories/meal_repository.dart';
import '../database/repositories/medication_repository.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/blood_sugar_chart.dart';
import '../widgets/highlight_card.dart';
import '../widgets/next_reminder_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/reminder_card.dart';

/// The first tab of the home screen: the health dashboard.
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  /// Live records loaded from the four FloorDB tables.
  List<GlucoseEntity> _records = [];
  List<MealEntity> _meals = [];
  List<MedicationEntity> _medications = [];
  List<InsulinEntity> _insulinRecords = [];

  /// One flag per stream; the tab only renders once all four loaded.
  bool _glucoseLoaded = false;
  bool _mealsLoaded = false;
  bool _medicationsLoaded = false;
  bool _insulinLoaded = false;

  /// Stream subscriptions; all cancelled in [dispose].
  StreamSubscription<List<GlucoseEntity>>? _glucoseSub;
  StreamSubscription<List<MealEntity>>? _mealsSub;
  StreamSubscription<List<MedicationEntity>>? _medicationsSub;
  StreamSubscription<List<InsulinEntity>>? _insulinSub;

  /// User name shown in the greeting (from the Firestore profile).
  String _userName = 'Bhanu';

  /// Returns a greeting based on the current time of day.
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// True once every data stream has emitted its first event.
  bool get _allLoaded =>
      _glucoseLoaded && _mealsLoaded && _medicationsLoaded && _insulinLoaded;

  /// The latest glucose value as text, or null when no readings exist.
  String? get _latestValue {
    if (_records.isEmpty) return null;
    return _records.first.level.toStringAsFixed(0);
  }

  /// Sum of the calories of all meals logged today.
  int get _todayCalories {
    final now = DateTime.now();
    final todayStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;
    final todayEnd = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ).millisecondsSinceEpoch;
    var total = 0.0;
    for (final m in _meals) {
      if (m.timestamp >= todayStart && m.timestamp <= todayEnd) {
        total += m.calories ?? 0;
      }
    }
    return total.round();
  }

  /// The most recently added medication, or null when none exist.
  MedicationEntity? get _latestMedication =>
      _medications.isEmpty ? null : _medications.first;

  /// The most recently logged insulin dose, or null when none exist.
  InsulinEntity? get _latestInsulin =>
      _insulinRecords.isEmpty ? null : _insulinRecords.first;

  /// Converts the readings into chart points for the trend graph.
  ///
  /// The records are stored newest first, so they are reversed to draw
  /// the oldest reading on the left of the chart.
  List<FlSpot> get _trendSpots {
    final spots = <FlSpot>[];
    final reversed = _records.reversed.toList();
    for (var i = 0; i < reversed.length; i++) {
      spots.add(FlSpot(i.toDouble(), reversed[i].level));
    }
    return spots;
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _init();
  }

  @override
  void dispose() {
    _glucoseSub?.cancel();
    _mealsSub?.cancel();
    _medicationsSub?.cancel();
    _insulinSub?.cancel();
    super.dispose();
  }

  /// Fetches the user's name from the Firestore profile.
  ///
  /// Used for the greeting. Falls back to the default name when the
  /// profile is missing or Firestore is unavailable.
  Future<void> _loadUserName() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    try {
      final profile = await FirestoreService().getUserProfile(user.uid);
      if (profile != null && profile.fullName.trim().isNotEmpty && mounted) {
        setState(() => _userName = profile.fullName.trim());
      }
    } catch (_) {
      // Keep the default name if Firestore is unavailable.
    }
  }

  /// Subscribes to the four FloorDB streams (glucose, meals,
  /// medications, insulin).
  ///
  /// Called once in [initState]. Each stream updates its own list and
  /// marks itself as loaded. Errors keep the tab usable by simply
  /// marking the stream as loaded.
  Future<void> _init() async {
    try {
      final glucoseRepo = await GlucoseRepository.getInstance();
      if (!mounted) return;
      _glucoseSub = glucoseRepo.watchAll().listen((records) {
        if (!mounted) return;
        setState(() {
          _records = records;
          _glucoseLoaded = true;
        });
      });
    } catch (_) {
      if (mounted) setState(() => _glucoseLoaded = true);
    }

    try {
      final mealRepo = await MealRepository.getInstance();
      if (!mounted) return;
      _mealsSub = mealRepo.watchAll().listen((meals) {
        if (!mounted) return;
        setState(() {
          _meals = meals;
          _mealsLoaded = true;
        });
      });
    } catch (_) {
      if (mounted) setState(() => _mealsLoaded = true);
    }

    try {
      final medicationRepo = await MedicationRepository.getInstance();
      if (!mounted) return;
      _medicationsSub = medicationRepo.watchAll().listen((medications) {
        if (!mounted) return;
        setState(() {
          _medications = medications;
          _medicationsLoaded = true;
        });
      });
    } catch (_) {
      if (mounted) setState(() => _medicationsLoaded = true);
    }

    try {
      final insulinRepo = await InsulinRepository.getInstance();
      if (!mounted) return;
      _insulinSub = insulinRepo.watchAll().listen((records) {
        if (!mounted) return;
        setState(() {
          _insulinRecords = records;
          _insulinLoaded = true;
        });
      });
    } catch (_) {
      if (mounted) setState(() => _insulinLoaded = true);
    }
  }

  /// Formats a whole number with comma separators (e.g. 1234 -> "1,234").
  String _formatNumber(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
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

  /// Convert a "HH:mm" string into the next DateTime it occurs.
  ///
  /// If the time has already passed today, tomorrow is used instead.
  /// Returns null when the string cannot be parsed (e.g. "HH:mm" only).
  DateTime? _nextOccurrence(String hhmm, DateTime now) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    var when = DateTime(now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    return when;
  }

  /// The single next upcoming reminder across all medications and
  /// insulin records, or null when no reminders exist.
  ///
  /// Only records with their reminder enabled are considered, so a
  /// medication or insulin entry with reminders turned off is skipped.
  /// Compares the next occurrence of every reminder time and keeps the
  /// earliest one, recording whether it is a medication or insulin
  /// reminder and at what 12-hour time it fires.
  NextReminderInfo? get _nextReminder {
    final now = DateTime.now();
    ({DateTime when, String type, String name})? best;
    for (final m in _medications) {
      if (!m.reminderEnabled) continue; // skip disabled reminders
      final when = _nextOccurrence(m.reminderTime, now);
      if (when != null && (best == null || when.isBefore(best.when))) {
        best = (when: when, type: 'Medication', name: m.name);
      }
    }
    for (final i in _insulinRecords) {
      if (!i.reminderEnabled) continue; // skip disabled reminders
      final when = _nextOccurrence(i.time, now);
      if (when != null && (best == null || when.isBefore(best.when))) {
        best = (when: when, type: 'Insulin', name: i.name);
      }
    }
    if (best == null) return null;
    return (
      type: best.type,
      name: best.name,
      time: _formatTime(
        '${best.when.hour.toString().padLeft(2, '0')}:'
        '${best.when.minute.toString().padLeft(2, '0')}',
      ),
    );
  }

  /// Formats a dose for display: whole numbers lose the decimal part.
  String _formatDose(double dose) {
    if (dose == dose.roundToDouble()) return dose.toInt().toString();
    return dose.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with the time-based greeting and tagline.
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_greeting()}, $_userName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Text(
              'Track Your Health, Live Better',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      // Full-page spinner until every stream has loaded once.
      body: !_allLoaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Highlight cards for blood sugar and calories.
                Row(
                  children: [
                    Expanded(
                      child: HighlightCard(
                        icon: Icons.bloodtype,
                        label: "Today's Blood Sugar",
                        value: _latestValue ?? '--',
                        unit: 'mg/dL',
                        color: AppColors.primaryBlue,
                        bgColor: AppColors.lightBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HighlightCard(
                        icon: Icons.local_fire_department,
                        label: "Today's Calories",
                        value: _formatNumber(_todayCalories),
                        unit: 'kcal',
                        color: AppColors.warningAmber,
                        bgColor: AppColors.warningAmber.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Next upcoming reminder across medications and insulin.
                NextReminderCard(
                  reminder: _nextReminder,
                ),
                const SizedBox(height: 12),
                // Reminder cards for medication and insulin, stacked
                // vertically so they never get squished on narrow phones.
                ReminderCard(
                  icon: Icons.medication_outlined,
                  title: 'Medication',
                  subtitle: _latestMedication == null
                      ? 'No medication recorded'
                      : '${_latestMedication!.name} '
                            '${_latestMedication!.dosage}',
                  time: _latestMedication == null
                      ? '--'
                      : (_latestMedication!.reminderEnabled
                            ? _formatTime(_latestMedication!.reminderTime)
                            : 'Off'),
                  color: AppColors.softGreen,
                ),
                const SizedBox(height: 12),
                ReminderCard(
                  icon: Icons.biotech_outlined,
                  title: 'Insulin',
                  subtitle: _latestInsulin == null
                      ? 'No insulin recorded'
                      : '${_latestInsulin!.name} '
                            '${_formatDose(_latestInsulin!.dose)} units',
                  time: _latestInsulin == null
                      ? '--'
                      : (_latestInsulin!.reminderEnabled
                            ? _formatTime(_latestInsulin!.time)
                            : 'Off'),
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(height: 20),
                // Quick actions heading and shortcuts.
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                // Quick actions: blood sugar and medication.
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.bloodtype,
                        label: 'Blood Sugar',
                        color: AppColors.primaryBlue,
                        onTap: () =>
                            Navigator.pushNamed(context, '/add-glucose'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.medication,
                        label: 'Medication',
                        color: AppColors.softGreen,
                        onTap: () =>
                            Navigator.pushNamed(context, '/medication'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quick actions: insulin and meals.
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.biotech,
                        label: 'Insulin',
                        color: AppColors.warningAmber,
                        onTap: () => Navigator.pushNamed(context, '/insulin'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.restaurant,
                        label: 'Meals',
                        color: AppColors.errorRed,
                        onTap: () =>
                            Navigator.pushNamed(context, '/meal-tracker'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Blood sugar trend heading.
                Text(
                  'Blood Sugar Trend',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                // Card containing the trend line chart.
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                    child: SizedBox(
                      height: 200,
                      // Empty message while no readings exist.
                      child: _trendSpots.isEmpty
                          ? Center(
                              child: Text(
                                'No readings yet',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.subtitleGrey),
                              ),
                            )
                          : BloodSugarChart(spots: _trendSpots),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}