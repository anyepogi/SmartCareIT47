/// Per-location clinic operating schedule. Each location only operates on
/// specific weekdays, within one fixed daily session. Appointments no
/// longer have time slots: each one gets a queue number for its clinic and
/// date instead (see queue_helper.php in the backend).
library;

const Map<String, List<int>> locationActiveWeekdays = {
  'Guagua': [DateTime.wednesday, DateTime.friday],
  'Lubao': [DateTime.wednesday, DateTime.friday],
  'Sta. Rita': [DateTime.tuesday, DateTime.wednesday, DateTime.friday],
};

/// (startHour, startMinute, endHour, endMinute) in 24h time.
const Map<String, (int, int, int, int)> locationHourRange = {
  'Guagua': (13, 0, 15, 0),
  'Lubao': (10, 0, 12, 0),
  'Sta. Rita': (15, 0, 17, 0),
};

/// The clinic's session hours, like "3:00pm - 5:00pm", or null for an
/// unknown location.
String? sessionTimeLabel(String location) {
  final range = locationHourRange[location];
  if (range == null) return null;
  final (startH, startM, endH, endM) = range;
  return '${_formatTime(startH * 60 + startM)} - ${_formatTime(endH * 60 + endM)}';
}

/// Whether [location]'s session on [date] has already ended, so it can no
/// longer be booked (only possible for today).
bool isSessionOver(String location, DateTime date) {
  final range = locationHourRange[location];
  if (range == null) return true;
  final (_, _, endH, endM) = range;
  final close = DateTime(date.year, date.month, date.day, endH, endM);
  return !DateTime.now().isBefore(close);
}

/// The appointment's queue number as shown to people, like "SO3" (Sta.
/// Rita, Online, 3rd) or "GW1" (Guagua, Walk-in, 1st). Old appointments
/// from before queue numbers fall back to their time slot.
String appointmentQueueLabel(Map<String, dynamic> appointment) {
  return appointment['queue_code'] as String? ??
      appointment['time_slot'] as String? ??
      '';
}

/// Whether the patient has already been sent to the doctor or is with the
/// doctor now. A patient can't reschedule or cancel such an appointment
/// (the backend refuses too); only staff can.
bool isAppointmentWithDoctor(Map<String, dynamic> appointment) {
  final status = appointment['status'];
  return status == 'sent_to_doctor' || status == 'serving';
}

/// The patients still waiting behind [current] on the Now Serving
/// screen: the same clinic, still booked or sent to the doctor (not
/// completed, no-show, or cancelled), in queue-number order.
List<Map<String, dynamic>> waitingInLine(
  List<Map<String, dynamic>> queue,
  Map<String, dynamic> current,
) {
  final waiting = queue
      .where(
        (p) =>
            p['appointment_id'] != current['appointment_id'] &&
            p['location'] == current['location'] &&
            (p['status'] == 'booked' || p['status'] == 'sent_to_doctor'),
      )
      .toList();
  waiting.sort(
    (a, b) => ((a['queue_number'] as num?) ?? 0).compareTo(
      (b['queue_number'] as num?) ?? 0,
    ),
  );
  return waiting;
}

/// The "Now Serving" value: the queue number being served and how many
/// queue numbers that clinic has given out that day, like "SO2/5". Falls back to
/// just the queue number when the total is unknown, and "--" when no one
/// is being served.
String nowServingLabel(Map<String, dynamic>? serving, int? total) {
  if (serving == null) return '--';
  final label = appointmentQueueLabel(serving);
  if (label.isEmpty) return '--';
  return total != null && total > 0 ? '$label/$total' : label;
}

/// The time shown for an appointment: the clinic's session hours, or the
/// old time slot for appointments from before queue numbers.
String appointmentTimeLabel(Map<String, dynamic> appointment) {
  return appointment['session_time'] as String? ??
      appointment['time_slot'] as String? ??
      sessionTimeLabel(appointment['location'] as String? ?? '') ??
      '';
}

/// The appointment ID as shown to people, 7 digits like "0000088".
String appointmentIdLabel(Map<String, dynamic> appointment) =>
    '${appointment['appointment_id'] ?? ''}'.padLeft(7, '0');

/// "Walk-in" or "Online", from the backend's booking_type.
String bookingTypeLabel(Map<String, dynamic> appointment) =>
    appointment['booking_type'] == 'walk_in' ? 'Walk-in' : 'Online';

String _formatTime(int minutesSinceMidnight) {
  final h = minutesSinceMidnight ~/ 60;
  final m = minutesSinceMidnight % 60;
  final period = h >= 12 ? 'pm' : 'am';
  var h12 = h % 12;
  if (h12 == 0) h12 = 12;
  return '$h12:${m.toString().padLeft(2, '0')}$period';
}

/// Whether [date]'s weekday is one of [location]'s active clinic days.
bool isDateValidForLocation(String location, DateTime date) {
  final days = locationActiveWeekdays[location];
  if (days == null) return false;
  return days.contains(date.weekday);
}

/// All clinic locations, in canonical display order.
const List<String> clinicLocations = ['Sta. Rita', 'Guagua', 'Lubao'];
