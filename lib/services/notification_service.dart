// Handles all local notifications: reminders for meds and insulin.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Singleton service that handles all local notifications.
class NotificationService {
  /// The one shared instance used across the whole app.
  static final NotificationService instance = NotificationService._();

  /// Private constructor, use [instance] instead.
  NotificationService._();

  /// The flutter_local_notifications plugin.
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Offset for insulin ids so they never clash with medication ids.
  static const int _insulinIdOffset = 100000;

  // Cached settings, loaded once from shared_preferences.
  bool _enabled = true;
  bool _sound = true;
  bool _vibration = true;
  bool _settingsLoaded = false;

  /// SharedPreferences keys for the settings.
  static const String _enabledKey = 'notifications_enabled';
  static const String _soundKey = 'notifications_sound';
  static const String _vibrationKey = 'notifications_vibration';

  // --- Notification id helpers ---

  /// Notification id for a medication record (its database id).
  static int medicationNotificationId(int recordId) => recordId;

  /// Notification id for an insulin record (database id + offset).
  static int insulinNotificationId(int recordId) => _insulinIdOffset + recordId;

  // Initialization

  /// Sets up timezones and the notification plugin. Called once at startup.
  Future<void> initializeNotifications() async {
    try {
      // Load the saved settings.
      await _loadSettings();

      // Set up timezones so reminders fire at the right local time.
      tzdata.initializeTimeZones();
      // We schedule in UTC but build times from the device's local clock,
      // so reminders still fire at the correct local moment.
      tz.setLocalLocation(tz.UTC);

      // Plugin settings for Android and iOS.
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is asked for manually, not automatically.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings: initializationSettings);
    } catch (_) {
      // If setup fails, just keep running without notifications.
    }
  }

  /// Asks for notification permission. Returns true when granted.
  Future<bool> requestPermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android 13+ needs this runtime permission.
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        // Older Android returns null, which means allowed.
        return granted ?? true;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }
    } catch (_) {
      // If asking fails, treat it as denied.
      return false;
    }
    // Desktop and web don't need this, just allow it.
    return true;
  }

  /// Asks for permission on the first launch (only once).
  Future<void> handleFirstLaunchPermission(BuildContext context) async {
    const requestedKey = 'notifications_permission_requested';
    const messageShownKey = 'notifications_permission_message_shown';

    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );
    } catch (_) {
      // If prefs fail (e.g. in tests), skip asking.
      return;
    }

    // Only ask on the very first launch.
    if (prefs.getBool(requestedKey) ?? false) return;
    await prefs.setBool(requestedKey, true);

    final granted = await requestPermissions();
    if (granted) return;

    // Show the help dialog only once too.
    if (prefs.getBool(messageShownKey) ?? false) return;
    await prefs.setBool(messageShownKey, true);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notifications are disabled'),
        content: const Text(
          'Medication and insulin reminders need notification permission. '
          'You can enable them later in your phone\'s app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Settings (enable / sound / vibration)

  /// Loads saved settings from shared_preferences (once).
  Future<void> _loadSettings() async {
    if (_settingsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );
      _enabled = prefs.getBool(_enabledKey) ?? true;
      _sound = prefs.getBool(_soundKey) ?? true;
      _vibration = prefs.getBool(_vibrationKey) ?? true;
      _settingsLoaded = true;
    } catch (_) {
      // Fall back to defaults (all on) if prefs fail.
    }
  }

  /// True when notifications are enabled.
  Future<bool> isEnabled() async {
    await _loadSettings();
    return _enabled;
  }

  /// True when reminder sounds are on.
  Future<bool> isSoundEnabled() async {
    await _loadSettings();
    return _sound;
  }

  /// True when reminder vibrations are on.
  Future<bool> isVibrationEnabled() async {
    await _loadSettings();
    return _vibration;
  }

  /// Turns notifications on or off. Off also cancels all pending ones.
  Future<void> setEnabled(bool value) async {
    await _loadSettings();
    _enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );
      await prefs.setBool(_enabledKey, value);
    } catch (_) {
      // If saving fails, don't break the toggle.
    }
    if (!value) await cancelAllNotifications();
  }

  /// Turns reminder sound on or off.
  Future<void> setSoundEnabled(bool value) async {
    await _loadSettings();
    _sound = value;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );
      await prefs.setBool(_soundKey, value);
    } catch (_) {
      // If saving fails, don't break the toggle.
    }
  }

  /// Turns reminder vibration on or off.
  Future<void> setVibrationEnabled(bool value) async {
    await _loadSettings();
    _vibration = value;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );
      await prefs.setBool(_vibrationKey, value);
    } catch (_) {
      // If saving fails, don't break the toggle.
    }
  }

  // Notification details

  /// Builds the notification details for every reminder.
  NotificationDetails _notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_channel',
        'Medication & Insulin Reminders',
        channelDescription: 'Reminders to take your medication or insulin',
        importance: Importance.high,
        priority: Priority.high,
        playSound: _sound,
        enableVibration: _vibration,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: _sound,
        presentBadge: true,
      ),
    );
  }

  /// Next "HH:mm" time as a UTC TZDateTime, or null if invalid.
  tz.TZDateTime? _nextOccurrence(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    // Build it from the device's local clock.
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // If it already passed today, use tomorrow.
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    // Convert to UTC for the timezone package.
    final utc = scheduled.toUtc();
    return tz.TZDateTime(
      tz.local,
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    );
  }

  // Scheduling reminders

  /// Schedules the reminder for one medication.
  Future<bool> scheduleMedicationReminder(
    int recordId,
    String name,
    String reminderTime, {
    DateTime? endDate,
    bool repeatDaily = true,
  }) async {
    await _loadSettings();
    // Don't schedule if notifications are off.
    if (!_enabled) return false;
    // Web doesn't support scheduled notifications.
    if (kIsWeb) return false;

    // Skip meds whose course already ended.
    if (endDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      if (end.isBefore(today)) return false;
    }

    final scheduled = _nextOccurrence(reminderTime);
    if (scheduled == null) return false; // invalid time, nothing to schedule.

    try {
      await _plugin.zonedSchedule(
        id: medicationNotificationId(recordId),
        title: 'Medication Reminder',
        body: 'Time to take your medication: $name',
        scheduledDate: scheduled,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // Repeats daily, or just once if repeatDaily is off.
        matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
      );
      return true;
    } catch (_) {
      // A failed schedule must not crash the app.
      return false;
    }
  }

  /// Schedules the reminder for one insulin record.
  Future<bool> scheduleInsulinReminder(
    int recordId,
    String name,
    String time, {
    bool repeatDaily = true,
  }) async {
    await _loadSettings();
    // Don't schedule if notifications are off.
    if (!_enabled) return false;
    // Web doesn't support scheduled notifications.
    if (kIsWeb) return false;

    final scheduled = _nextOccurrence(time);
    if (scheduled == null) return false; // invalid time, nothing to schedule.

    try {
      await _plugin.zonedSchedule(
        id: insulinNotificationId(recordId),
        title: 'Insulin Reminder',
        body: 'Time to take your insulin injection: $name',
        scheduledDate: scheduled,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // Repeats daily, or just once if repeatDaily is off.
        matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
      );
      return true;
    } catch (_) {
      // A failed schedule must not crash the app.
      return false;
    }
  }

  // Cancelling notifications

  /// Cancels one notification by id (used when a record is deleted).
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _plugin.cancel(id: notificationId);
    } catch (_) {
      // Cancelling one that's not there is fine.
    }
  }

  /// Cancels every pending notification.
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Nothing pending is fine too.
    }
  }

  // Instant notifications

  /// Shows a notification right away (no scheduling).
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _loadSettings();
    if (!_enabled) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _notificationDetails(),
      );
    } catch (_) {
      // Don't crash if it fails.
    }
  }
}
