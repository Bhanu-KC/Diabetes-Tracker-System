// Dashboard tab showing the user's health summary at a glance.


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

/// The first home tab: the health dashboard.
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  /// Live records from the four FloorDB tables.
  List<GlucoseEntity> _records = [];
  List<MealEntity> _meals = [];
  List<MedicationEntity> _medications = [];
  List<InsulinEntity> _insulinRecords = [];

  /// One flag per stream; render only after all four load.
  bool _glucoseLoaded = false;
  bool _mealsLoaded = false;
  bool _medicationsLoaded = false;
  bool _insulinLoaded = false;

  /// Stream subscriptions, cancelled in [dispose].
  StreamSubscription<List<GlucoseEntity>>? _glucoseSub;
  StreamSubscription<List<MealEntity>>? _mealsSub;
  StreamSubscription<List<MedicationEntity>>? _medicationsSub;
  StreamSubscription<List<InsulinEntity>>? _insulinSub;

  /// User name shown in the greeting.
  String _userName = 'Bhanu';

  /// Greeting based on the time of day.
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// True when every stream has loaded.
  bool get _allLoaded =>
      _glucoseLoaded && _mealsLoaded && _medicationsLoaded && _insulinLoaded;

  /// Latest glucose value as text, or null if none.
  String? get _latestValue {
    if (_records.isEmpty) return null;
    return _records.first.level.toStringAsFixed(0);
  }

  /// Calories from all meals logged today.
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

  /// Latest medication, or null if none.
  MedicationEntity? get _latestMedication =>
      _medications.isEmpty ? null : _medications.first;

  /// Latest insulin dose, or null if none.
  InsulinEntity? get _latestInsulin =>
      _insulinRecords.isEmpty ? null : _insulinRecords.first;

  /// Readings as chart points, oldest on the left.
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

  /// Fetches the user's name for the greeting.
  Future<void> _loadUserName() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    try {
      final profile = await FirestoreService().getUserProfile(user.uid);
      if (profile != null && profile.fullName.trim().isNotEmpty && mounted) {
        setState(() => _userName = profile.fullName.trim());
      }
    } catch (_) {
      // Keep the default name if Firestore fails.
    }
  }

  /// Subscribes to the four FloorDB streams.
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

  /// Formats a number with commas, e.g. 1234 -> "1,234".
  String _formatNumber(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  /// Converts "HH:mm" to a 12-hour time like "2:30 PM".
  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return time;
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Next time "HH:mm" happens (tomorrow if it passed today).
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

  // The next reminder across all medications and insulin records.
  NextReminderInfo? get _nextReminder {
    final now = DateTime.now();
    DateTime? bestWhen;
    String? bestType;
    String? bestName;
    for (final m in _medications) {
      if (!m.reminderEnabled) continue; // skip disabled reminders
      final when = _nextOccurrence(m.reminderTime, now);
      if (when != null && (bestWhen == null || when.isBefore(bestWhen))) {
        bestWhen = when;
        bestType = 'Medication';
        bestName = m.name;
      }
    }
    for (final i in _insulinRecords) {
      if (!i.reminderEnabled) continue; // skip disabled reminders
      final when = _nextOccurrence(i.time, now);
      if (when != null && (bestWhen == null || when.isBefore(bestWhen))) {
        bestWhen = when;
        bestType = 'Insulin';
        bestName = i.name;
      }
    }
    if (bestWhen == null) return null;
    return NextReminderInfo(
      bestType!,
      bestName!,
      _formatTime(
        '${bestWhen.hour.toString().padLeft(2, '0')}:'
        '${bestWhen.minute.toString().padLeft(2, '0')}',
      ),
    );
  }

  /// Shows whole doses without decimals.
  String _formatDose(double dose) {
    if (dose == dose.roundToDouble()) return dose.toInt().toString();
    return dose.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with greeting and tagline.
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
      // Spinner until every stream has loaded.
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
                // Medication and insulin reminder cards, stacked.
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
                const SizedBox(height: 10),
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
                // Quick actions heading.
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
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
                      // Message when there are no readings.
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
