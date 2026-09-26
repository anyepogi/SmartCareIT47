import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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

/* This class handles reminding a patient about an appointment that is
coming up soon. It uses the phone's own alarm and notification system
(not the internet) to show a reminder 1 hour before and again 10
minutes before the appointment time, so these still work even if the
app is closed, as long as the phone stays on and the user allowed
notification permissions. It also checks the backend for anything new
that happened while the app was closed, like a staff member cancelling
an appointment, and shows those as real phone notifications too. */
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
      // Fall back to whatever default timezone package already set.
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
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

  /// Parses a slot start time like "9:00am - 9:30am" into hour/minute.
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

  static int _reminderIdFor(int appointmentId, int offset) =>
      appointmentId * 10 + offset;

  /* This tells the phone to set two alarms for one appointment: one that
  goes off 1 hour before, and one that goes off 10 minutes before. It
  first cancels any old reminders already set for this same appointment,
  so if the appointment gets rescheduled, the old wrong time reminders
  do not also go off. If the calculated alarm time has already passed,
  it simply does not get scheduled (see _scheduleIfFuture below). */
  static Future<void> scheduleForAppointment(
    Map<String, dynamic> appointment,
  ) async {
    await initialize();

    final appointmentId = appointment['appointment_id'] as int?;
    final scheduleDate = appointment['schedule_date'] as String?;
    final timeSlot = appointment['time_slot'] as String?;
    final location = appointment['location'] as String?;
    if (appointmentId == null || scheduleDate == null || timeSlot == null) {
      return;
    }

    await cancelForAppointment(appointmentId);

    final date = DateTime.tryParse(scheduleDate);
    final slotStart = _parseSlotStart(timeSlot);
    if (date == null || slotStart == null) return;

    final appointmentTime = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      slotStart.$1,
      slotStart.$2,
    );

    final dateLabel =
        "${_monthNames[appointmentTime.month - 1]} ${appointmentTime.day}";

    await _scheduleIfFuture(
      id: _reminderIdFor(appointmentId, 1),
      fireTime: appointmentTime.subtract(const Duration(hours: 1)),
      title: "Appointment in 1 hour",
      body:
          "Your appointment on $dateLabel at $timeSlot"
          "${location != null ? ' ($location)' : ''} is coming up. "
          "Please arrive earlier than your schedule, at least 10 minutes before.",
    );

    await _scheduleIfFuture(
      id: _reminderIdFor(appointmentId, 2),
      fireTime: appointmentTime.subtract(const Duration(minutes: 10)),
      title: "Appointment in 10 minutes",
      body:
          "Your appointment on $dateLabel at $timeSlot"
          "${location != null ? ' ($location)' : ''} is starting soon. "
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

  /* This is a backup check that runs whenever the dashboard loads. It
  looks at how much time is left before the appointment and, if it is
  now within 1 hour or within 10 minutes, it also saves a notification
  in the backend database (not just a phone alarm), so it shows up in
  the app's own Notifications list too. It remembers which reminders it
  already sent using the phone's local storage, so the same reminder
  does not get created again and again every time the dashboard loads. */
  static Future<void> checkAndNotifyIfDue({
    required int userId,
    required Map<String, dynamic> appointment,
  }) async {
    final appointmentId = appointment['appointment_id'] as int?;
    final scheduleDate = appointment['schedule_date'] as String?;
    final timeSlot = appointment['time_slot'] as String?;
    final location = appointment['location'] as String?;
    if (appointmentId == null || scheduleDate == null || timeSlot == null) {
      return;
    }

    final date = DateTime.tryParse(scheduleDate);
    final slotStart = _parseSlotStart(timeSlot);
    if (date == null || slotStart == null) return;

    final appointmentTime = DateTime(
      date.year,
      date.month,
      date.day,
      slotStart.$1,
      slotStart.$2,
    );
    final remaining = appointmentTime.difference(DateTime.now());
    if (remaining.isNegative) return;

    final dateLabel = "${_monthNames[date.month - 1]} ${date.day}";
    final locationSuffix = location != null ? ' ($location)' : '';
    final prefs = await SharedPreferences.getInstance();

    if (remaining <= const Duration(hours: 1)) {
      await _notifyOnce(
        prefs: prefs,
        dedupeKey: 'notified_1hr_$appointmentId',
        userId: userId,
        title: "Appointment in 1 hour",
        message:
            "Your appointment on $dateLabel at $timeSlot$locationSuffix is "
            "coming up. Please arrive earlier than your schedule, at least "
            "10 minutes before.",
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
      // Leave the dedupe flag unset so it retries on the next check.
    }
  }

  /* This checks the backend for every notification saved for this user,
  and compares it to the highest notification id this device has seen
  before (saved in local phone storage). Any notification with a higher
  id than before is new, so it pops up as a real phone notification.
  This is how things that happen elsewhere, like a doctor calling the
  patient's number or a secretary cancelling an appointment, still show
  up as a phone notification even though there is no real push
  notification service. It only works while the app is open and this
  function gets called, usually when a dashboard screen loads. This
  function also updates the unread notification count badge shown on
  the bell icon at the top of the screen. */
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
      // First time syncing on this device: baseline silently so we don't
      // spam old history as if it just happened.
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
