// Reports screen with health stats summaries.


import 'dart:async';

import 'package:flutter/material.dart';
import '../database/entities/glucose_entity.dart';
import '../database/entities/insulin_entity.dart';
import '../database/entities/meal_entity.dart';
import '../database/entities/medication_entity.dart';
import '../database/repositories/glucose_repository.dart';
import '../database/repositories/insulin_repository.dart';
import '../database/repositories/meal_repository.dart';
import '../database/repositories/medication_repository.dart';
import '../theme/app_theme.dart';

/// Shows summary reports from the recorded data.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  /// Live records from the four FloorDB tables.
  List<GlucoseEntity> _glucose = [];
  List<MedicationEntity> _medications = [];
  List<InsulinEntity> _insulinRecords = [];
  List<MealEntity> _meals = [];

  /// One flag per stream; wait until all have loaded.
  bool _glucoseLoaded = false;
  bool _medicationsLoaded = false;
  bool _insulinLoaded = false;
  bool _mealsLoaded = false;

  /// Stream subscriptions, cancelled in [dispose].
  StreamSubscription<List<GlucoseEntity>>? _glucoseSub;
  StreamSubscription<List<MedicationEntity>>? _medicationsSub;
  StreamSubscription<List<InsulinEntity>>? _insulinSub;
  StreamSubscription<List<MealEntity>>? _mealsSub;

  /// True when every stream has loaded.
  bool get _allLoaded =>
      _glucoseLoaded && _medicationsLoaded && _insulinLoaded && _mealsLoaded;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _glucoseSub?.cancel();
    _medicationsSub?.cancel();
    _insulinSub?.cancel();
    _mealsSub?.cancel();
    super.dispose();
  }

  /// Subscribes to the four FloorDB streams.
  Future<void> _init() async {
    try {
      final repo = await GlucoseRepository.getInstance();
      if (!mounted) return;
      _glucoseSub = repo.watchAll().listen((records) {
        if (!mounted) return;
        setState(() {
          _glucose = records;
          _glucoseLoaded = true;
        });
      });
    } catch (_) {
      if (mounted) setState(() => _glucoseLoaded = true);
    }

    try {
      final repo = await MedicationRepository.getInstance();
      if (!mounted) return;
      _medicationsSub = repo.watchAll().listen((records) {
        if (!mounted) return;
        setState(() {
          _medications = records;
          _medicationsLoaded = true;
        });
      });
    } catch (_) {
      if (mounted) setState(() => _medicationsLoaded = true);
    }

    try {
      final repo = await InsulinRepository.getInstance();
      if (!mounted) return;
      _insulinSub = repo.watchAll().listen((records) {
        if (!mounted) return;
        setState(() {
          _insulinRecords = records;
          _insulinLoaded = true;
        });
      });
    } catch (_) {
      if (mounted) setState(() => _insulinLoaded = true);
    }

    try {
      final repo = await MealRepository.getInstance();
      if (!mounted) return;
      _mealsSub = repo.watchAll().listen((records) {
        if (!mounted) return;
        setState(() {
          _meals = records;
          _mealsLoaded = true;
        });
      });
    } catch (_) {
      if (mounted) setState(() => _mealsLoaded = true);
    }
  }


  /// Start-of-day timestamp [days] days ago.
  int _daysAgo(int days) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    return start.millisecondsSinceEpoch;
  }

  /// Average glucose level, or null when the list is empty.
  double? _avgGlucose(List<GlucoseEntity> records) {
    if (records.isEmpty) return null;
    var sum = 0.0;
    for (final r in records) {
      sum += r.level;
    }
    return sum / records.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(title: const Text('Reports')),
      // Spinner until every stream has loaded.
      body: !_allLoaded
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(theme),
    );
  }

  /// Builds the list of report cards.
  Widget _buildBody(ThemeData theme) {
    // Readings from the last 7 and 30 days.
    final weekly = _glucose.where((g) => g.timestamp >= _daysAgo(7)).toList();
    final monthly = _glucose.where((g) => g.timestamp >= _daysAgo(30)).toList();

    final weekAvg = _avgGlucose(weekly);
    final monthAvg = _avgGlucose(monthly);

    // Medication and insulin summaries.
    final activeMedicationCount = _medications.length;
    final insulinThisWeek = _insulinRecords
        .where((i) => i.timestamp >= _daysAgo(7))
        .toList();
    final insulinDailyAvg = insulinThisWeek.isEmpty
        ? null
        : insulinThisWeek.fold<double>(0, (sum, i) => sum + i.dose) / 7;

    // Calories over the last 7 days vs the 2000 goal.
    final mealsThisWeek = _meals
        .where((m) => m.timestamp >= _daysAgo(7))
        .toList();
    final caloriesPerDay = mealsThisWeek.isEmpty
        ? null
        : mealsThisWeek.fold<double>(0, (sum, m) => sum + (m.calories ?? 0)) /
              7;
    // 2000 is the default goal, change later if needed
    final goalPct = caloriesPerDay == null
        ? null
        : (caloriesPerDay / 2000 * 100).round();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Weekly blood sugar report card.
        _reportCard(
          theme,
          Icons.calendar_view_week,
          'Weekly Report',
          weekAvg == null
              ? 'No readings this week'
              : 'Average: ${weekAvg.toStringAsFixed(0)} mg/dL  ${weekly.length} readings',
          AppColors.primaryBlue,
        ),
        const SizedBox(height: 12),
        // Monthly blood sugar report card.
        _reportCard(
          theme,
          Icons.calendar_month,
          'Monthly Report',
          '${monthAvg == null ? 'No readings' : 'Average: ${monthAvg.toStringAsFixed(0)} mg/dL'}  ${monthly.length} readings',
          AppColors.softGreen,
        ),
        const SizedBox(height: 14),
        // 30-day blood sugar average card.
        _reportCard(
          theme,
          Icons.bloodtype,
          'Average Blood Sugar',
          monthAvg == null
              ? 'No readings in the last 30 days'
              : '${monthAvg.toStringAsFixed(0)} mg/dL over last 30 days',
          AppColors.warningAmber,
        ),
        const SizedBox(height: 12),
        // Medication summary card.
        _reportCard(
          theme,
          Icons.medication,
          'Medication Summary',
          activeMedicationCount == 0
              ? 'No medications recorded'
              : '$activeMedicationCount active medication${activeMedicationCount == 1 ? '' : 's'}',
          AppColors.primaryBlue,
        ),
        const SizedBox(height: 12),
        // Insulin summary card.
        _reportCard(
          theme,
          Icons.biotech,
          'Insulin Summary',
          insulinThisWeek.isEmpty
              ? 'No injections this week'
              : '${insulinDailyAvg!.toStringAsFixed(1)} units/day average  ${insulinThisWeek.length} injections this week',
          AppColors.softGreen,
        ),
        const SizedBox(height: 10),
        // Calories summary card.
        _reportCard(
          theme,
          Icons.local_fire_department,
          'Calories Summary',
          caloriesPerDay == null
              ? 'No meals this week'
              : 'Avg ${caloriesPerDay.toStringAsFixed(0)} kcal/day $goalPct% of daily goal',
          AppColors.warningAmber,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// One report card: icon, title and description.
  Widget _reportCard(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      ),
    );
  }
}
