import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/location_schedule.dart';
import '../services/appointment/appointment_service.dart';
import '../services/navigation_transitions.dart';
import '../services/notifications/appointment_reminder_service.dart';
import '../services/profile/profile_service.dart';
import '../state/app_session.dart';
import '../widgets/loading_button.dart';
import '../widgets/session_info_card.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';
import 'confirm.dart';

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

const List<String> _shortWeekdayNames = [
  "Mon",
  "Tue",
  "Wed",
  "Thu",
  "Fri",
  "Sat",
  "Sun",
];

const List<String> _longWeekdayNames = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
];

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final List<String> locations = clinicLocations;
  String? selectedLocation = "Sta. Rita";

  late final DateTime _today;
  late DateTime selectedDate;
  bool _isBooking = false;
  OverlayEntry? _bookingOverlayEntry;

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(widget.initialDate ?? DateTime.now());
    selectedDate = _firstValidDateFor(selectedLocation, _today);
    _checkExistingAppointment();
  }

  /// Returns [from] if it's a valid clinic day for [location], otherwise the
  /// next valid day within the visible window (falling back to [from] if
  /// none is found, e.g. an unknown location).
  DateTime _firstValidDateFor(String? location, DateTime from) {
    if (location == null) return from;
    final days = _buildVisibleWeekDays(from, location);
    if (days.isEmpty) return from;
    for (final option in days) {
      if (_isSameDate(option.date, from)) return from;
    }
    return days.first.date;
  }

  Future<String> _currentPatientName() async {
    final userId = SmartCareSession.currentUserId;
    if (userId == null) return "Patient";
    try {
      final profile = await ProfileService.getProfile(userId);
      final name =
          "${profile['first_name'] ?? ''} ${profile['middle_name'] ?? ''} ${profile['last_name'] ?? ''}"
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
      return name.isEmpty ? "Patient" : name;
    } catch (_) {
      return "Patient";
    }
  }

  Future<void> _checkExistingAppointment() async {
    final userId = SmartCareSession.currentUserId;
    if (userId == null) return;

    try {
      final appt = await AppointmentService.getUpcoming(userId);
      if (!mounted || appt == null) return;

      final date = DateTime.parse(appt['schedule_date'] as String);
      final dateTime =
          "${_formatScheduleDate(date)}, ${appointmentTimeLabel(appt)}";
      final patientName = await _currentPatientName();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        smartCareRoute(
          transition: SmartCareTransition.subPage,
          builder: (context) => AppointmentConfirmScreen(
            dateTime: dateTime,
            patientName: patientName,
            appointmentId: appt['reference_no'] as String? ?? '',
            location: appt['location'] as String,
            queueCode: appt['queue_code'] as String?,
            isExistingView: true,
          ),
        ),
      );
    } catch (_) {
      // Ignore: let the patient continue to the booking form.
    }
  }

  String get _dateKey =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  List<_DayOption> get _visibleDays =>
      _buildVisibleWeekDays(_today, selectedLocation);

  /* Books the chosen clinic and date. There is no time slot to pick: the
  backend gives the patient the next queue number for that session (like
  SO3 if two people booked Sta. Rita that day before them). */
  Future<void> _confirmBooking() async {
    if (_isBooking) {
      return;
    }

    final bookedLocation = selectedLocation;
    if (bookedLocation == null ||
        !_visibleDays.any((day) => _isSameDate(day.date, selectedDate))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a location and date.")),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });
    _showBookingOverlay();

    BookingResult booking;
    try {
      booking = await AppointmentService.book(
        userId: SmartCareSession.currentUserId ?? 0,
        location: bookedLocation,
        date: _dateKey,
      );
    } catch (e) {
      _hideBookingOverlay();
      if (!mounted) return;
      setState(() {
        _isBooking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    }

    AppointmentReminderService.scheduleForAppointment({
      'appointment_id': booking.appointmentId,
      'schedule_date': _dateKey,
      'location': bookedLocation,
      'queue_code': booking.queueCode,
    });

    if (!mounted) {
      _hideBookingOverlay();
      return;
    }

    _hideBookingOverlay();
    setState(() {
      _isBooking = false;
    });

    final fullDateTime =
        "${_formatScheduleDate(selectedDate)}, ${sessionTimeLabel(bookedLocation) ?? ''}";
    final patientName = await _currentPatientName();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      smartCareRoute(
        transition: SmartCareTransition.subPage,
        builder: (context) => AppointmentConfirmScreen(
          dateTime: fullDateTime,
          patientName: patientName,
          appointmentId: booking.code,
          location: bookedLocation,
          queueCode: booking.queueCode,
        ),
      ),
    );
  }

  void _showBookingOverlay() {
    if (_bookingOverlayEntry != null) {
      return;
    }

    _bookingOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Material(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Confirming your appointment...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_bookingOverlayEntry!);
  }

  void _hideBookingOverlay() {
    _bookingOverlayEntry?.remove();
    _bookingOverlayEntry = null;
  }

  @override
  void dispose() {
    _hideBookingOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F2E4),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.schedule,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 380
                    ? 12.0
                    : 16.0;
                final padding = horizontalPadding;
                final dense = constraints.maxHeight < 470;
                final sectionGap = dense ? 6.0 : 8.0;
                final blockGap = dense ? 12.0 : 14.0;
                final cardGap = dense ? 8.0 : 8.0;
                final buttonGap = dense ? 12.0 : 14.0;
                final days = _visibleDays;

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SmartCareDashboardHeader(
                      title: "Book Appointment",
                      subtitle:
                          "Choose a clinic and date to get your queue number.",
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(padding, 14, padding, 22),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionLabel("Select Location"),
                              SizedBox(height: sectionGap),
                              _LocationSelector(
                                locations: locations,
                                selectedLocation: selectedLocation,
                                onSelected: (location) {
                                  setState(() {
                                    selectedLocation = location;
                                    selectedDate = _firstValidDateFor(
                                      location,
                                      selectedDate.isBefore(_today)
                                          ? _today
                                          : selectedDate,
                                    );
                                  });
                                },
                              ),
                              SizedBox(height: blockGap),
                              const _SectionLabel("Select Date"),
                              SizedBox(height: sectionGap),
                              _DaySelector(
                                days: days,
                                selectedDate: selectedDate,
                                onSelected: (day) {
                                  setState(() {
                                    selectedDate = day.date;
                                  });
                                },
                              ),
                              SizedBox(height: blockGap),
                              const _SectionLabel("Clinic Session"),
                              SizedBox(height: sectionGap),
                              SessionInfoCard(
                                location: selectedLocation ?? '',
                                date: selectedDate,
                              ),
                              SizedBox(height: blockGap),
                              SizedBox(
                                width: double.infinity,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 48,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isBooking
                                        ? null
                                        : _confirmBooking,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF006B2D),
                                      disabledBackgroundColor: const Color(
                                        0xCC006B2D,
                                      ),
                                      disabledForegroundColor: Colors.white,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      "Confirm Appointment",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF006B2D),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _LocationSelector extends StatelessWidget {
  const _LocationSelector({
    required this.locations,
    required this.selectedLocation,
    required this.onSelected,
  });

  final List<String> locations;
  final String? selectedLocation;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 10.0;
        final itemWidth =
            (constraints.maxWidth - (gap * (locations.length - 1))) /
            locations.length;

        return Row(
          children: [
            for (var index = 0; index < locations.length; index++) ...[
              SizedBox(
                width: itemWidth,
                height: 44,
                child: _LocationChip(
                  label: locations[index],
                  isSelected: locations[index] == selectedLocation,
                  onTap: () => onSelected(locations[index]),
                ),
              ),
              if (index != locations.length - 1) SizedBox(width: gap),
            ],
          ],
        );
      },
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? const Color(0xFF006B2D) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF006B2D)
                    : const Color(0xFF62B36E),
                width: isSelected ? 0 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFF006B2D),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF006B2D),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.days,
    required this.selectedDate,
    required this.onSelected,
  });

  final List<_DayOption> days;
  final DateTime selectedDate;
  final ValueChanged<_DayOption> onSelected;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final gap = compact ? 10.0 : 14.0;
        final visibleItems = math.min(days.length, 7);
        final itemWidth =
            (constraints.maxWidth - (gap * (visibleItems - 1))) / visibleItems;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < days.length; index++) ...[
                SizedBox(
                  width: itemWidth.clamp(compact ? 44.0 : 68.0, 100.0),
                  height: compact ? 68 : 80,
                  child: _DayCard(
                    day: days[index],
                    isSelected: _isSameDate(selectedDate, days[index].date),
                    onTap: () => onSelected(days[index]),
                  ),
                ),
                if (index != days.length - 1) SizedBox(width: gap),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final _DayOption day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: day.semanticLabel,
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? const Color(0xFF006B2D) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                if (!isSelected)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      day.monthShort,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white70
                            : const Color(0xFF6E8D73),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      day.weekday,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF27943B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.day,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentDetailsCard extends StatelessWidget {
  const _AppointmentDetailsCard({required this.onChange});

  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _softCardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFD9EED8),
            child: Icon(
              Icons.article_rounded,
              color: Color(0xFF006B2D),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Consultation",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF006B2D),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "General check-up and consultation",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF404040),
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: const Text(
              "Change",
              style: TextStyle(
                color: Color(0xFF27943B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _softCardDecoration({
  Color borderColor = const Color(0xFFC7D8C5),
  Color backgroundColor = Colors.white,
}) {
  return BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F6B2F).withValues(alpha: 0.02),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class _DayOption {
  const _DayOption(this.date);

  final DateTime date;

  String get weekday => _shortWeekdayNames[date.weekday - 1];

  String get monthShort =>
      _monthNames[date.month - 1].substring(0, 3).toUpperCase();

  String get day => date.day.toString();

  String get semanticLabel {
    return "${_longWeekdayNames[date.weekday - 1]}, "
        "${_monthNames[date.month - 1]} ${date.day}, ${date.year}";
  }
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

/// Patients can view a rolling 1-month window starting today, filtered to
/// only the [location]'s active clinic weekdays. Today is left out once its
/// session has ended, since it can no longer be booked.
List<_DayOption> _buildVisibleWeekDays(DateTime today, String? location) {
  if (location == null) return [];
  final oneMonthOut = DateTime(today.year, today.month + 1, today.day);
  final days = <_DayOption>[];
  var day = today;
  while (!day.isAfter(oneMonthOut)) {
    if (isDateValidForLocation(location, day) &&
        !(_isSameDate(day, DateTime.now()) && isSessionOver(location, day))) {
      days.add(_DayOption(day));
    }
    day = day.add(const Duration(days: 1));
  }
  return days;
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _formatScheduleDate(DateTime date) {
  return "${_monthNames[date.month - 1]} ${date.day}, ${date.year}";
}
