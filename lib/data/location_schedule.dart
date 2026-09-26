/// Per-location clinic operating schedule. Each location only operates on
/// specific weekdays, within one fixed daily hour window, sliced into
/// 20-minute appointment slots.
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

const int appointmentSlotMinutes = 20;

/// Returns the full ordered list of time-slot strings for [location], e.g.
/// "1:00pm - 1:20pm". The order defines each slot's 1-based queue position.
List<String> timeSlotsForLocation(String location) {
  final range = locationHourRange[location];
  if (range == null) return [];
  final (startH, startM, endH, endM) = range;

  final slots = <String>[];
  var minutes = startH * 60 + startM;
  final endMinutes = endH * 60 + endM;
  while (minutes + appointmentSlotMinutes <= endMinutes) {
    slots.add(
      '${_formatTime(minutes)} - ${_formatTime(minutes + appointmentSlotMinutes)}',
    );
    minutes += appointmentSlotMinutes;
  }
  return slots;
}

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
