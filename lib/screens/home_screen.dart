/// Main home screen of the app (the shell after login).
///
/// This screen hosts a bottom navigation bar with four tabs: Home
/// (dashboard), History, Reports and Profile, plus a red emergency SOS
/// button in the centre. The dashboard tab shows live health summaries
/// (latest blood sugar, today's calories, medication and insulin
/// reminders), quick action shortcuts and a blood sugar trend chart.

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
import 'history_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

/// Shell screen with bottom navigation tabs and the SOS button.
///
/// Shown after a successful login. [HomeScreen] itself only manages
/// tab switching; each tab is a separate widget.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Index of the currently selected tab (0 = dashboard).
  int _currentIndex = 0;

  /// The four main tabs, kept alive as a stable list.
  final List<Widget> _pages = [
    const _DashboardTab(),
    const HistoryScreen(),
    const ReportsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The tab content for the selected index.
      body: _pages[_currentIndex],
      // Bottom navigation bar for switching between major pages.
      bottomNavigationBar: BottomAppBar(
        height: 64,
        color: AppColors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home tab (dashboard).
            _NavItem(
              icon: _currentIndex == 0 ? Icons.home : Icons.home_outlined,
              label: 'Home',
              isSelected: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            // History tab.
            _NavItem(
              icon: _currentIndex == 1 ? Icons.history : Icons.history_outlined,
              label: 'History',
              isSelected: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            // Space reserved for the centre SOS button.
            const SizedBox(width: 48),
            // Reports tab.
            _NavItem(
              icon: _currentIndex == 2
                  ? Icons.bar_chart
                  : Icons.bar_chart_outlined,
              label: 'Reports',
              isSelected: _currentIndex == 2,
              onTap: () => setState(() => _currentIndex = 2),
            ),
            // Profile tab.
            _NavItem(
              icon: _currentIndex == 3 ? Icons.person : Icons.person_outlined,
              label: 'Profile',
              isSelected: _currentIndex == 3,
              onTap: () => setState(() => _currentIndex = 3),
            ),
          ],
        ),
      ),
      // Emergency SOS button displayed prominently in the centre.
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: _showEmergencySheet,
          backgroundColor: const Color(0xFFE53935),
          elevation: 10,
          shape: const CircleBorder(),
          child: const Icon(Icons.emergency, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Opens the emergency assistance bottom sheet.
  ///
  /// Loads the user's emergency contact from Firestore (name and phone
  /// number) and shows it in a modal sheet. When no contact is saved,
  /// an empty state with instructions is shown instead.
  Future<void> _showEmergencySheet() async {
    final user = AuthService().currentUser;
    String? contactName;
    String? contactNumber;
    var loaded = false;
    if (user != null) {
      try {
        final profile = await FirestoreService().getUserProfile(user.uid);
        contactName = profile?.emergencyContactName;
        contactNumber = profile?.emergencyContactNumber;
        loaded = true;
      } catch (_) {
        // Show the sheet even when Firestore is unavailable.
        loaded = true;
      }
    } else {
      loaded = true;
    }
    if (!mounted) return;

    // Bottom sheet with the emergency contact information.
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small drag handle at the top of the sheet.
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.emergency, color: Color(0xFFE53935), size: 40),
              const SizedBox(height: 8),
              // Sheet title.
              Text(
                'Emergency Assistance',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              // Loading spinner, empty state or contact details.
              if (!loaded)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )
              else if (contactName == null || contactNumber == null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.contact_emergency_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No emergency contact saved',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add one from Edit Profile so help is always available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.subtitleGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                // Contact tile with name and phone number.
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(
                      Icons.contact_emergency,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  title: Text(
                    contactName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Call $contactNumber using your phone dialer'),
                ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Button that closes the sheet.
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// One item of the bottom navigation bar (icon and label).
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Dashboard Tab
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Dashboard tab showing the user's health summary at a glance.
///
/// Displays the latest blood sugar, today's calorie total, medication
/// and insulin reminders, quick action shortcuts and a blood sugar
/// trend chart. All data is live: the tab subscribes to the four
/// FloorDB streams and rebuilds automatically when records change.
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
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
  ({String type, String name, String time})? get _nextReminder {
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
                      child: _HighlightCard(
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
                      child: _HighlightCard(
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
                _NextReminderCard(
                  reminder: _nextReminder,
                ),
                const SizedBox(height: 12),
                // Reminder cards for medication and insulin.
                Row(
                  children: [
                    Expanded(
                      child: _ReminderCard(
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ReminderCard(
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
                    ),
                  ],
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
                      child: _QuickActionCard(
                        icon: Icons.bloodtype,
                        label: 'Blood Sugar',
                        color: AppColors.primaryBlue,
                        onTap: () =>
                            Navigator.pushNamed(context, '/add-glucose'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickActionCard(
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
                      child: _QuickActionCard(
                        icon: Icons.biotech,
                        label: 'Insulin',
                        color: AppColors.warningAmber,
                        onTap: () => Navigator.pushNamed(context, '/insulin'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickActionCard(
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
                          : _BloodSugarChart(spots: _trendSpots),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Highlight Card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Card showing one large highlighted value (e.g. latest blood sugar).
class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color bgColor;

  const _HighlightCard({
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
            // Label, e.g. "Today's Blood Sugar".
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            // Large value with its unit next to it.
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Reminder Card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Card reminding the user about their latest medication or insulin.
class _ReminderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _ReminderCard({
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
            // Title and subtitle text.
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Quick Action Card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Card showing the single next upcoming reminder.
///
/// Displays whether the reminder is for medication or insulin and the
/// time it will fire. When no reminder exists (no records with times)
/// the message "No upcoming reminders." is shown instead.
class _NextReminderCard extends StatelessWidget {
  /// The computed next reminder, or null when there is none.
  final ({String type, String name, String time})? reminder;

  const _NextReminderCard({required this.reminder});

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
            // Title and type/name text.
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

/// Tappable shortcut card that navigates to a major feature.
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Blood Sugar Trend Chart
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Line chart of the blood sugar trend using the fl_chart library.
///
/// Plots each reading as a point on a blue curved line with a light
/// fill underneath. The y-axis is fixed between 80 and 200 mg/dL and
/// the bottom axis labels reading order by weekday.
class _BloodSugarChart extends StatelessWidget {
  final List<FlSpot> spots;

  const _BloodSugarChart({required this.spots});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: spots.length > 1 ? spots.length - 1 : 1,
        minY: 80,
        maxY: 200,
        // Horizontal grid lines every 30 mg/dL.
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 30,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        // Axis labels: left shows 80/140/200, bottom shows weekdays.
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value == 80 || value == 140 || value == 200) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final index = value.toInt();
                if (index >= 0 && index < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      days[index],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        // The blue curved line with points and a light area below.
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primaryBlue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
            ),
          ),
        ],
        // Tooltip showing the value in mg/dL when touching the chart.
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toInt()} mg/dL',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
