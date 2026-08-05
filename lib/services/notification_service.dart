/// NotificationService - the brain of all local notifications.
///
/// This class is responsible for everything related to notifications:
///   * Initializing the flutter_local_notifications plugin and timezones.
///   * Asking the user for notification permission.
///   * Scheduling reminders for medications and insulin records.
///   * Cancelling reminders when records are deleted.
///   * Remembering the user's notification settings (enabled, sound,
///     vibration) using shared_preferences.
///
/// The class is used as a singleton: call
/// `NotificationService.instance` anywhere in the app to get the same
/// object. The reminder functions are called from the add/edit screens
/// (after saving a record) and from the delete flows (after deleting a
/// record).

library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Singleton service that manages all local notification behaviour.
class NotificationService {
  /// The one shared instance of the service used across the whole app.
  static final NotificationService instance = NotificationService._();

  /// Private constructor (see [instance] for how the service is used).
  NotificationService._();

  /// The plugin object provided by the flutter_local_notifications package.
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Offset added to insulin notification ids so they never clash with
  /// medication ids (both database tables start counting at 1).
  static const int _insulinIdOffset = 100000;

  // Cached setting values. They are loaded from shared_preferences the
  // first time they are needed, then kept in memory for speed.
  bool _enabled = true;
  bool _sound = true;
  bool _vibration = true;
  bool _settingsLoaded = false;

  /// SharedPreferences keys used to persist the notification settings.
  static const String _enabledKey = 'notifications_enabled';
  static const String _soundKey = 'notifications_sound';
  static const String _vibrationKey = 'notifications_vibration';

  // ------------------------------------------------------------------
  // Notification id helpers
  // ------------------------------------------------------------------

  /// Returns the notification id used for a medication record.
  ///
  /// The database id is used directly. Called when scheduling a
  /// medication reminder or cancelling it on delete.
  static int medicationNotificationId(int recordId) => recordId;

  /// Returns the notification id used for an insulin record.
  ///
  /// The [_insulinIdOffset] is added so insulin notifications never
  /// overwrite medication notifications with the same database id.
  static int insulinNotificationId(int recordId) => _insulinIdOffset + recordId;

  // ------------------------------------------------------------------
  // Initialization
  // ------------------------------------------------------------------

  /// Initializes timezones and the notification plugin.
  ///
  /// Called once from `main()` before the app starts. Sets up the local
  /// timezone (so reminders fire at the correct local time) and tells
  /// the plugin which icon/channel settings to use.
  Future<void> initializeNotifications() async {
    try {
      // Load the user's saved settings (enabled, sound, vibration).
      await _loadSettings();

      // Initialize the timezone database (needed to schedule times).
      tzdata.initializeTimeZones();
      // Reminders are scheduled in UTC. Because the next-occurrence times
      // are computed from the device's local clock (see _nextOccurrence),
      // the notifications still fire at the correct local moment without
      // depending on any native timezone plugin.
      tz.setLocalLocation(tz.UTC);

      // Plugin settings for Android (uses the launcher icon) and iOS.
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested manually, not automatically.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings: initializationSettings);
    } catch (_) {
      // If initialization fails the app must keep working without
      // notifications, so the error is simply swallowed here.
    }
  }

  /// Asks the user for notification permission (Android 13+, iOS).
  ///
  /// Shows the system permission dialog. Returns true when the user
  /// granted permission, false otherwise. On Android 12 and older the
  /// permission is granted automatically, so true is returned. On
  /// platforms that do not need a permission dialog (desktop/web), true
  /// is returned so the flow never blocks.
  Future<bool> requestPermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android 13+ needs the POST_NOTIFICATIONS runtime permission.
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        // Older Android versions return null and are always allowed.
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
      // Any error means we could not ask; treat as denied.
      return false;
    }
    // Desktop and web do not need a button-driven permission request.
    return true;
  }

  /// Requests permission on the first launch of the app.
  ///
  /// The permission dialog is only shown once (a shared_preferences flag
  /// remembers that it was already shown). If the user denies the
  /// request, a helpful dialog explains that medication reminders need
  /// notification permission.
  Future<void> handleFirstLaunchPermission(BuildContext context) async {
    const requestedKey = 'notifications_permission_requested';
    const messageShownKey = 'notifications_permission_message_shown';

    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );
    } catch (_) {
      // If preferences cannot be read (e.g. inside a test) the app must
      // continue without asking for permission.
      return;
    }

    // Only request the permission on the very first launch.
    if (prefs.getBool(requestedKey) ?? false) return;
    await prefs.setBool(requestedKey, true);

    final granted = await requestPermissions();
    if (granted) return;

    // Show the helpful explanation dialog only once.
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

  // ------------------------------------------------------------------
  // Settings (enable / sound / vibration)
  // ------------------------------------------------------------------

  /// Loads the saved settings from shared_preferences once.
  ///
  /// Called by [initializeNotifications] and lazily by the getters so
  /// the toggles always show the correct state.
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
      // Keep the default (all on) when prefs are unavailable.
    }
  }

  /// Returns true when notifications are currently enabled.
  Future<bool> isEnabled() async {
    await _loadSettings();
    return _enabled;
  }

  /// Returns true when reminder sounds are enabled.
  Future<bool> isSoundEnabled() async {
    await _loadSettings();
    return _sound;
  }

  /// Returns true when reminder vibrations are enabled.
  Future<bool> isVibrationEnabled() async {
    await _loadSettings();
    return _vibration;
  }

  /// Turns notifications on or off.
  ///
  /// When turned off, every pending notification is cancelled so no
  /// future reminders fire. When turned on again, the user's existing
  /// records are re-scheduled by the settings screen.
  Future<void> setEnabled(bool value) async {
    await _loadSettings();
    _enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );
      await prefs.setBool(_enabledKey, value);
    } catch (_) {
      // Persistence failure should not break the toggle.
    }
    if (!value) await cancelAllNotifications();
  }

  /// Turns the reminder sound on or off (affects future reminders).
  Future<void> setSoundEnabled(bool value) async {
    await _loadSettings();
    _sound = value;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );
      await prefs.setBool(_soundKey, value);
    } catch (_) {
      // Persistence failure should not break the toggle.
    }
  }

  /// Turns the reminder vibration on or off (affects future reminders).
  Future<void> setVibrationEnabled(bool value) async {
    await _loadSettings();
    _vibration = value;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );
      await prefs.setBool(_vibrationKey, value);
    } catch (_) {
      // Persistence failure should not break the toggle.
    }
  }

  // ------------------------------------------------------------------
  // Notification details
  // ------------------------------------------------------------------

  /// Builds the notification details used for every reminder.
  ///
  /// A high importance/priority channel makes the reminder appear
  /// prominently. Sound and vibration follow the user's settings.
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

  /// Computes the next occurrence of an "HH:mm" time in the device's
  /// local timezone, expressed as a UTC `TZDateTime`.
  ///
  /// Using the device's own clock (`DateTime.now()`) means the correct
  /// local time is used even without a native timezone plugin. The time
  /// is converted to UTC because `tz.local` is UTC. If the time has
  /// already passed today, tomorrow is used instead. Returns null when
  /// the time string is invalid.
  tz.TZDateTime? _nextOccurrence(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    // Build the next occurrence using the device's local clock.
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // If the time already passed today, schedule it for tomorrow.
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    // Convert the local moment to UTC for the timezone package.
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

  // ------------------------------------------------------------------
  // Scheduling reminders
  // ------------------------------------------------------------------

  /// Schedules the reminder for one medication.
  ///
  /// Called automatically after a medication is added or edited. When
  /// [repeatDaily] is true the notification repeats every day at
  /// [reminderTime] (an "HH:mm" string); otherwise it fires only once.
  /// When the course has already ended ([endDate] is in the past)
  /// nothing is scheduled. Returns true when the reminder was scheduled
  /// successfully.
  Future<bool> scheduleMedicationReminder(
    int recordId,
    String name,
    String reminderTime, {
    DateTime? endDate,
    bool repeatDaily = true,
  }) async {
    await _loadSettings();
    // Never schedule when the user disabled notifications.
    if (!_enabled) return false;
    // Scheduled notifications are not supported on the web.
    if (kIsWeb) return false;

    // Skip medications whose course has already finished.
    if (endDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      if (end.isBefore(today)) return false;
    }

    final scheduled = _nextOccurrence(reminderTime);
    if (scheduled == null) return false; // invalid reminder time.

    try {
      await _plugin.zonedSchedule(
        id: medicationNotificationId(recordId),
        title: 'Medication Reminder',
        body: 'Time to take your medication: $name',
        scheduledDate: scheduled,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // Repeat every day at the same time (not weekly). When daily
        // repeat is off the reminder is a one-time notification.
        matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
      );
      return true;
    } catch (_) {
      // Scheduling failure must never crash the app.
      return false;
    }
  }

  /// Schedules the reminder for one insulin record.
  ///
  /// Called automatically after an insulin record is added or edited.
  /// When [repeatDaily] is true the notification repeats every day at
  /// [time] (an "HH:mm" string); otherwise it fires only once. Returns
  /// true when the reminder was scheduled successfully.
  Future<bool> scheduleInsulinReminder(
    int recordId,
    String name,
    String time, {
    bool repeatDaily = true,
  }) async {
    await _loadSettings();
    // Never schedule when the user disabled notifications.
    if (!_enabled) return false;
    // Scheduled notifications are not supported on the web.
    if (kIsWeb) return false;

    final scheduled = _nextOccurrence(time);
    if (scheduled == null) return false; // invalid reminder time.

    try {
      await _plugin.zonedSchedule(
        id: insulinNotificationId(recordId),
        title: 'Insulin Reminder',
        body: 'Time to take your insulin injection: $name',
        scheduledDate: scheduled,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // Repeat every day at the same time (not weekly). When daily
        // repeat is off the reminder is a one-time notification.
        matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
      );
      return true;
    } catch (_) {
      // Scheduling failure must never crash the app.
      return false;
    }
  }

  // ------------------------------------------------------------------
  // Cancelling notifications
  // ------------------------------------------------------------------

  /// Cancels one scheduled notification by its notification id.
  ///
  /// Called when a medication or insulin record is deleted. Use the
  /// [medicationNotificationId] / [insulinNotificationId] helpers to
  /// get the correct id for a record.
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _plugin.cancel(id: notificationId);
    } catch (_) {
      // Cancelling a non-existent notification is harmless.
    }
  }

  /// Cancels every pending notification.
  ///
  /// Called when the user turns notifications off. Also useful as a
  /// cleanup for future features.
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // No pending notifications is a valid state.
    }
  }

  // ------------------------------------------------------------------
  // Instant notifications
  // ------------------------------------------------------------------

  /// Shows an instant notification immediately (no scheduling).
  ///
  /// Useful for immediate feedback (e.g. a test button). The id must be
  /// unique for every notification you want to show at the same time.
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
      // A failed instant notification must not crash the app.
    }
  }
}
