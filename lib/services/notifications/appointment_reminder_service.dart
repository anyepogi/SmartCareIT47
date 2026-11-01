import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/location_schedule.dart';
import '../../state/notification_center.dart';
import 'notification_service.dart';

const List<String> _monthNames = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

/// Phone reminders 1 hour and 10 minutes before an appointment. They're
/// scheduled on the phone itself, so they work even when the app is
/// closed. Also shows new backend notifications (like a cancelled
/// appointment) as phone notifications.
class AppointmentReminderService {
  AppointmentReminderService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Manila'));
    } catch (_) {
      // Keep the timezone package's default.
    }

<<<<<<< HEAD
    // Must match android:icon in AndroidManifest.xml. Release builds strip
    // unused images, so an icon the manifest doesn't use won't exist.
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
=======
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
<<<<<<< HEAD
    try {
      await _plugin.initialize(settings);
    } catch (_) {
      // Reminders just won't work; this must never stop the app opening.
    }
=======
    await _plugin.initialize(settings);
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
  }

  static Future<void> requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Gets the start hour and minute from a slot like "9:00am - 9:30am".
  static (int, int)? _parseSlotStart(String timeSlot) {
    final start = timeSlot.split('-').first.trim().toLowerCase();
    final match = RegExp(r'^(\d{1,2}):(\d{2})(am|pm)$').firstMatch(start);
    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final meridiem = match.group(3)!;

    if (meridiem == 'pm' && hour != 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;

    return (hour, minute);
  }

  /// Start time for the reminders: the session's opening time for queue
  /// number bookings, or the slot start for older bookings. Null if unknown.
  static DateTime? _appointmentStart(Map<String, dynamic> appointment) {
    final date = DateTime.tryParse(
      appointment['schedule_date'] as String? ?? '',
    );
    if (date == null) return null;
    final timeSlot = appointment['time_slot'] as String?;
    final (int, int)? start;
    if (timeSlot != null) {
      start = _parseSlotStart(timeSlot);
    } else {
      final range = locationHourRange[appointment['location'] as String? ?? ''];
      start = range == null ? null : (range.$1, range.$2);
    }
    if (start == null) return null;
    return DateTime(date.year, date.month, date.day, start.$1, start.$2);
  }

  /// " (Sta. Rita), queue no. SO3" style suffix for reminder messages.
  static String _whereSuffix(Map<String, dynamic> appointment) {
    final location = appointment['location'] as String?;
    final queueCode = appointment['queue_code'] as String?;
    return "${location != null ? ' ($location)' : ''}"
        "${queueCode != null ? ', queue no. $queueCode' : ''}";
  }

  static int _reminderIdFor(int appointmentId, int offset) =>
      appointmentId * 10 + offset;

  /// Sets the 1 hour and 10 minute reminders for an appointment. Old ones
  /// for the same appointment are cancelled first (in case it was
  /// rescheduled). Times that already passed are skipped.
  static Future<void> scheduleForAppointment(
    Map<String, dynamic> appointment,
  ) async {
    await initialize();

    final appointmentId = appointment['appointment_id'] as int?;
    if (appointmentId == null) return;

    await cancelForAppointment(appointmentId);

    final start = _appointmentStart(appointment);
    if (start == null) return;
    final appointmentTime = tz.TZDateTime.from(start, tz.local);
    final dateLabel = "${_monthNames[start.month - 1]} ${start.day}";
    final timeLabel = appointmentTimeLabel(appointment);
    final where = _whereSuffix(appointment);

    await _scheduleIfFuture(
      id: _reminderIdFor(appointmentId, 1),
      fireTime: appointmentTime.subtract(const Duration(hours: 1)),
      title: "Appointment in 1 hour",
      body:
          "Your appointment on $dateLabel at $timeLabel$where is coming up. "
          "Please be at the clinic before your queue number is called.",
    );

    await _scheduleIfFuture(
      id: _reminderIdFor(appointmentId, 2),
      fireTime: appointmentTime.subtract(const Duration(minutes: 10)),
      title: "Appointment in 10 minutes",
      body:
          "Your appointment on $dateLabel at $timeLabel$where is starting soon. "
          "Please head to the clinic now.",
    );
  }

  static Future<void> _scheduleIfFuture({
    required int id,
    required tz.TZDateTime fireTime,
    required String title,
    required String body,
  }) async {
    if (fireTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
      'appointment_reminders',
      'Appointment Reminders',
      channelDescription: 'Reminders before your scheduled appointment.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      fireTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels both reminders for the given appointment (e.g. after cancel).
  static Future<void> cancelForAppointment(int appointmentId) async {
    await _plugin.cancel(_reminderIdFor(appointmentId, 1));
    await _plugin.cancel(_reminderIdFor(appointmentId, 2));
  }

  /// Backup for the phone reminders, run when the dashboard loads. If the
  /// appointment is within 1 hour or 10 minutes, it also saves a
  /// notification in the backend. Sent ones are remembered in local
  /// storage so they aren't created again.
  static Future<void> checkAndNotifyIfDue({
    required int userId,
    required Map<String, dynamic> appointment,
  }) async {
    final appointmentId = appointment['appointment_id'] as int?;
    if (appointmentId == null) return;

    final appointmentTime = _appointmentStart(appointment);
    if (appointmentTime == null) return;
    final remaining = appointmentTime.difference(DateTime.now());
    if (remaining.isNegative) return;

    final dateLabel =
        "${_monthNames[appointmentTime.month - 1]} ${appointmentTime.day}";
    final timeSlot = appointmentTimeLabel(appointment);
    final locationSuffix = _whereSuffix(appointment);
    final prefs = await SharedPreferences.getInstance();

    if (remaining <= const Duration(hours: 1)) {
      await _notifyOnce(
        prefs: prefs,
        dedupeKey: 'notified_1hr_$appointmentId',
        userId: userId,
        title: "Appointment in 1 hour",
        message:
            "Your appointment on $dateLabel at $timeSlot$locationSuffix is "
            "coming up. Please be at the clinic before your queue number "
            "is called.",
      );
    }

    if (remaining <= const Duration(minutes: 10)) {
      await _notifyOnce(
        prefs: prefs,
        dedupeKey: 'notified_10min_$appointmentId',
        userId: userId,
        title: "Appointment in 10 minutes",
        message:
            "Your appointment on $dateLabel at $timeSlot$locationSuffix is "
            "starting soon. Please head to the clinic now.",
      );
    }
  }

  static Future<void> _notifyOnce({
    required SharedPreferences prefs,
    required String dedupeKey,
    required int userId,
    required String title,
    required String message,
  }) async {
    if (prefs.getBool(dedupeKey) == true) return;
    try {
      await NotificationService.create(
        userId: userId,
        title: title,
        message: message,
        type: "Reminders",
        targetRoute: "/appointment",
      );
      await prefs.setBool(dedupeKey, true);
    } catch (_) {
      // Not marked as sent, so it tries again next time.
    }
  }

  /// Shows new backend notifications as phone notifications. Anything with
  /// a higher id than the last one seen on this phone counts as new. There's
  /// no push service, so this only works while the app is open (usually when
  /// a dashboard loads). Also updates the unread badge on the bell icon.
  static Future<void> syncAndShowNewNotifications(int userId) async {
    await initialize();

    List<Map<String, dynamic>> notifications;
    try {
      notifications = await NotificationService.getForUser(userId);
    } catch (_) {
      return;
    }
    NotificationCenter.updateFromList(notifications);
    if (notifications.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastSeenKey = 'last_seen_notification_id_$userId';
    final lastSeenId = prefs.getInt(lastSeenKey);

    final maxId = notifications
        .map((n) => n['notification_id'] as int)
        .reduce((a, b) => a > b ? a : b);

    if (lastSeenId == null) {
      // First sync on this phone: just save the latest id so old
      // notifications don't pop up.
      await prefs.setInt(lastSeenKey, maxId);
      return;
    }

    final unseen = notifications.where(
      (n) => (n['notification_id'] as int) > lastSeenId,
    );
    for (final n in unseen) {
      await _showNow(
        id: n['notification_id'] as int,
        title: n['title'] as String,
        body: n['message'] as String,
      );
    }

    await prefs.setInt(lastSeenKey, maxId);
  }

  static Future<void> _showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'app_notifications',
      'App Notifications',
      channelDescription: 'Updates about your appointments.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id, title, body, details);
  }
}
