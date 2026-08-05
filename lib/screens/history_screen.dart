/// History screen showing past health activity as a timeline.
///
/// Reached from the bottom navigation "History" tab. Merges records from
/// all four FloorDB tables (blood sugar, medication, insulin, meals) into
/// one timeline. Supports searching and filtering by category. Data is
/// live via the repository streams.

library;

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

/// The screen that displays all recorded activity in one timeline.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// Currently selected category filter (default: show everything).
  String _selectedFilter = 'All';

  /// Controller and value for the search box.
  final _searchController = TextEditingController();
  String _searchQuery = '';

  /// Live records from the four FloorDB tables.
  List<GlucoseEntity> _glucose = [];
  List<MedicationEntity> _medications = [];
  List<InsulinEntity> _insulinRecords = [];
  List<MealEntity> _meals = [];

  /// One flag per stream; the timeline waits until all have loaded.
  bool _glucoseLoaded = false;
  bool _medicationsLoaded = false;
  bool _insulinLoaded = false;
  bool _mealsLoaded = false;

  /// Stream subscriptions; all cancelled in [dispose].
  StreamSubscription<List<GlucoseEntity>>? _glucoseSub;
  StreamSubscription<List<MedicationEntity>>? _medicationsSub;
  StreamSubscription<List<InsulinEntity>>? _insulinSub;
  StreamSubscription<List<MealEntity>>? _mealsSub;

  /// The category filter chips shown below the search box.
  final _filters = ['All', 'Blood Sugar', 'Medication', 'Insulin', 'Meals'];

  /// True once every data stream has emitted its first event.
  bool get _allLoaded =>
      _glucoseLoaded && _medicationsLoaded && _insulinLoaded && _mealsLoaded;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Subscribes to the four FloorDB streams used by the timeline.
  ///
  /// Called once in [initState]. Each stream updates its own list and
  /// marks itself as loaded so the timeline only renders when all data
  /// is available.
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

  @override
  void dispose() {
    _searchController.dispose();
    _glucoseSub?.cancel();
    _medicationsSub?.cancel();
    _insulinSub?.cancel();
    _mealsSub?.cancel();
    super.dispose();
  }

  /// Whether the given [section] should be shown for the current filter.
  bool _shouldShow(String section) {
    return _selectedFilter == 'All' || _selectedFilter == section;
  }

  /// Whether the given [text] matches the current search query.
  ///
  /// Returns true when the search box is empty. Comparison ignores case.
  bool _matches(String text) {
    if (_searchQuery.isEmpty) return true;
    return text.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          // Sort button (records are always shown newest first).
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Sorted by date')));
            },
            tooltip: 'Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search box used to filter the timeline.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search records...',
                prefixIcon: const Icon(Icons.search),
                // Clear button shown while a query is active.
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Horizontal row of category filter chips.
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _filters.map((f) {
                final selected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedFilter = f),
                    selectedColor: AppColors.lightBlue,
                    checkmarkColor: AppColors.primaryBlue,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  /// Builds the timeline body with filtered sections.
  ///
  /// Shows a loading spinner until all streams load, an empty state when
  /// nothing matches, otherwise one timeline section per category. Each
  /// section is limited to the 10 newest records.
  Widget _buildBody(ThemeData theme) {
    if (!_allLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    // Each category's records filtered by the search query.
    final visibleGlucose = _glucose
        .where((g) => _matches(g.level.toStringAsFixed(0)))
        .toList();
    final visibleMedications = _medications
        .where((m) => _matches('${m.name} ${m.dosage}'))
        .toList();
    final visibleInsulin = _insulinRecords
        .where((i) => _matches('${i.name} ${i.dose}'))
        .toList();
    final visibleMeals = _meals
        .where((m) => _matches('${m.name} ${m.mealType}'))
        .toList();

    // Whether anything should be drawn at all.
    final hasAny =
        visibleGlucose.isNotEmpty ||
        visibleMedications.isNotEmpty ||
        visibleInsulin.isNotEmpty ||
        visibleMeals.isNotEmpty;

    if (!hasAny) {
      // Empty state with a hint related to the current search.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_outlined,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No records found',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppColors.subtitleGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try a different search term'
                    : 'Your activity will appear here',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.subtitleGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Timeline sections, one per category with any visible records.
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Blood sugar section.
        if (_shouldShow('Blood Sugar') && visibleGlucose.isNotEmpty)
          _sectionHeader(
            theme,
            'Blood Sugar',
            Icons.bloodtype,
            AppColors.primaryBlue,
          ),
        if (_shouldShow('Blood Sugar'))
          for (final g in visibleGlucose.take(10))
            _timelineCard(
              theme,
              Icons.bloodtype,
              '${g.level.toStringAsFixed(0)} mg/dL',
              '${g.mealContext} ${_glucoseStatus(g.level)}',
              _formatTimestamp(g.timestamp),
              _glucoseStatusColor(g.level),
              _glucoseStatusColor(g.level).withValues(alpha: 0.1),
            ),
        // Medication section.
        if (_shouldShow('Medication') && visibleMedications.isNotEmpty)
          _sectionHeader(
            theme,
            'Medication',
            Icons.medication,
            AppColors.softGreen,
          ),
        if (_shouldShow('Medication'))
          for (final m in visibleMedications.take(10))
            _timelineCard(
              theme,
              Icons.medication,
              '${m.name} ${m.dosage}',
              '${m.frequency}  ${_formatTime(m.reminderTime)}',
              'Active from ${_formatDate(m.startDate)}',
              AppColors.softGreen,
              AppColors.lightGreen,
            ),
        // Insulin section.
        if (_shouldShow('Insulin') && visibleInsulin.isNotEmpty)
          _sectionHeader(
            theme,
            'Insulin',
            Icons.biotech,
            AppColors.primaryBlue,
          ),
        if (_shouldShow('Insulin'))
          for (final i in visibleInsulin.take(10))
            _timelineCard(
              theme,
              Icons.biotech,
              '${i.name} ${i.dose.round()} units',
              '${i.site}  ${_formatTime(i.time)}',
              _formatTimestamp(i.timestamp),
              AppColors.primaryBlue,
              AppColors.lightBlue,
            ),
        // Meals section.
        if (_shouldShow('Meals') && visibleMeals.isNotEmpty)
          _sectionHeader(
            theme,
            'Meals',
            Icons.restaurant,
            AppColors.warningAmber,
          ),
        if (_shouldShow('Meals'))
          for (final m in visibleMeals.take(10))
            _timelineCard(
              theme,
              Icons.restaurant,
              m.name,
              '${m.mealType} ${m.calories?.round() ?? 0} kcal',
              _formatTimestamp(m.timestamp),
              AppColors.warningAmber,
              AppColors.warningAmber.withValues(alpha: 0.1),
            ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Classifies a glucose level into Low / Normal / High / Very High.
  String _glucoseStatus(double level) {
    if (level < 70) return 'Low';
    if (level <= 140) return 'Normal';
    if (level <= 180) return 'High';
    return 'Very High';
  }

  /// Returns the status colour for a glucose level (red/green/amber).
  Color _glucoseStatusColor(double level) {
    if (level < 70) return AppColors.errorRed;
    if (level <= 140) return AppColors.softGreen;
    if (level <= 180) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  /// Formats a timestamp as "Today/Yesterday, HH:MM AM/PM" or a date.
  String _formatTimestamp(int millis) {
    final t = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(t.year, t.month, t.day);
    final dayDiff = today.difference(thatDay).inDays;
    final period = t.hour >= 12 ? 'PM' : 'AM';
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final time = '$hour:${t.minute.toString().padLeft(2, '0')} $period';
    if (dayDiff == 0) return 'Today, $time';
    if (dayDiff == 1) return 'Yesterday, $time';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${t.day} ${months[t.month - 1]} ${t.year}, $time';
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

  /// Formats a millisecond timestamp as "dd Mon yyyy" (e.g. "05 Aug 2026").
  String _formatDate(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final padded = d.day.toString().padLeft(2, '0');
    return '$padded ${months[d.month - 1]} ${d.year}';
  }

  /// Header row shown above each category in the timeline.
  Widget _sectionHeader(
    ThemeData theme,
    String title,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// One timeline row: an icon dot with a connector above a card.
  ///
  /// The card shows the record's title, subtitle and timestamp, and its
  /// colour reflects the record type or blood sugar status.
  Widget _timelineCard(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    String time,
    Color statusColor,
    Color bgColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon dot plus the vertical connector line below it.
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: statusColor, size: 16),
              ),
              Container(width: 2, height: 50, color: Colors.grey.shade200),
            ],
          ),
          const SizedBox(width: 12),
          // Card with the record details.
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Record title.
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Record subtitle.
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    // Timestamp with a small clock icon.
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.subtitleGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
