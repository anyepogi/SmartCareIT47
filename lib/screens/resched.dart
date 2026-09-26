import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/location_schedule.dart';
import '../services/appointment/appointment_service.dart';
import '../services/navigation_transitions.dart';
import '../services/notifications/appointment_reminder_service.dart';
import '../services/profile/profile_service.dart';
import '../services/schedule/schedule_service.dart';
import '../state/app_session.dart';
import '../widgets/loading_button.dart';
import 'confirm.dart';
import 'appointment_screen.dart' as appointmentScreen;

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
  const AppointmentBookingScreen({
    super.key,
    this.initialDate,
    this.existingAppointmentId,
  });

  final DateTime? initialDate;

  /// The appointment being rescheduled, if any. When set, this appointment
  /// is cancelled right before the new one is booked so it doesn't conflict
  /// with the one-booking-per-day rule.
  final int? existingAppointmentId;

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final List<String> locations = clinicLocations;
  String? selectedLocation = "Sta. Rita";

  List<String> get slots => timeSlotsForLocation(selectedLocation ?? '');

  late final DateTime _today;
  late DateTime selectedDate;
  String? selectedSlot;
  bool _isBooking = false;

  Set<String> unavailableSlots = {};
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(widget.initialDate ?? DateTime.now());
    selectedDate = _firstValidDateFor(selectedLocation, _today);
    _loadBlockedSlots();
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

  /// Merges server-reported unavailable slots with slots whose time has
  /// already passed today, so patients can't rebook a time that's already
  /// gone by when they're viewing today's schedule.
  Set<String> get _effectiveUnavailableSlots {
    if (!_isSameDate(selectedDate, DateTime.now())) return unavailableSlots;

    final now = DateTime.now();
    final pastSlots = slots.where((slot) {
      final start = _parseSlotStartTime(slot);
      if (start == null) return false;
      final slotTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        start.$1,
        start.$2,
      );
      return !slotTime.isAfter(now);
    });

    return {...unavailableSlots, ...pastSlots};
  }

  String get _dateKey =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  Future<void> _loadBlockedSlots() async {
    final location = selectedLocation;
    if (location == null) return;

    setState(() {
      _isLoadingSlots = true;
    });
    try {
      final blocked = await ScheduleService.getBlockedSlots(
        location: location,
        date: _dateKey,
      );
      if (!mounted) return;
      setState(() {
        unavailableSlots = blocked.toSet();
        if (_effectiveUnavailableSlots.contains(selectedSlot)) {
          selectedSlot = null;
        }
        _isLoadingSlots = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingSlots = false;
      });
    }
  }

  List<_DayOption> get _visibleDays =>
      _buildVisibleWeekDays(_today, selectedLocation);

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

  Future<void> _confirmBooking() async {
    if (_isBooking) {
      return;
    }

    final bookedSlot = selectedSlot;
    final bookedLocation = selectedLocation;
    if (bookedLocation == null || bookedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a location, date, and time slot."),
        ),
      );
      return;
    }

    if (_effectiveUnavailableSlots.contains(bookedSlot)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "That time slot has already passed. Please pick another.",
          ),
        ),
      );
      _loadBlockedSlots();
      return;
    }

    setState(() {
      _isBooking = true;
    });

    final existingId = widget.existingAppointmentId;
    if (existingId != null) {
      try {
        await AppointmentService.cancel(existingId);
        await AppointmentReminderService.cancelForAppointment(existingId);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isBooking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        return;
      }
    }

    BookingResult booking;
    try {
      booking = await AppointmentService.book(
        userId: SmartCareSession.currentUserId ?? 0,
        location: bookedLocation,
        date: _dateKey,
        timeSlot: bookedSlot,
        isReschedule: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBooking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      _loadBlockedSlots();
      return;
    }

    AppointmentReminderService.scheduleForAppointment({
      'appointment_id': booking.appointmentId,
      'schedule_date': _dateKey,
      'time_slot': bookedSlot,
      'location': bookedLocation,
    });

    if (!mounted) {
      return;
    }

    setState(() {
      _isBooking = false;
    });

    final appointmentDateTime = _formatScheduleDate(selectedDate);
    final fullDateTime = "$appointmentDateTime at $bookedSlot";
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _visibleDays;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F2E4),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Back button at top-left
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  smartCareRoute(
                                    transition: SmartCareTransition.subPage,
                                    builder: (context) =>
                                        const appointmentScreen.AppointmentBookingScreen(),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.arrow_back,
                                color: Color(0xFF1C5D22),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Title centered horizontally below the back button
                            const Center(
                              child: Text(
                                "Reschedule Appointment",
                                style: TextStyle(
                                  color: Color(0xFF006B2D),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                        ),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionLabel("Select Location"),
                                const SizedBox(height: 8),
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
                                      selectedSlot = null;
                                    });
                                    _loadBlockedSlots();
                                  },
                                ),
                                const SizedBox(height: 14),
                                const _SectionLabel("Select Date"),
                                const SizedBox(height: 8),
                                _DaySelector(
                                  days: days,
                                  selectedDate: selectedDate,
                                  onSelected: (day) {
                                    setState(() {
                                      selectedDate = day.date;
                                    });
                                    _loadBlockedSlots();
                                  },
                                ),
                                const SizedBox(height: 14),
                                const _SectionLabel("Select Time Slot"),
                                const SizedBox(height: 8),
                                if (_isLoadingSlots)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: LinearProgressIndicator(
                                      color: Color(0xFF006B2D),
                                    ),
                                  ),
                                _TimeSlotGrid(
                                  slots: slots,
                                  selectedSlot: selectedSlot,
                                  unavailableSlots: _effectiveUnavailableSlots,
                                  onSelected: (slot) {
                                    setState(() {
                                      selectedSlot = slot;
                                    });
                                  },
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 48,
                                    ),
                                    child: LoadingButton(
                                      isLoading: _isBooking,
                                      onPressed: _confirmBooking,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF006B2D,
                                        ),
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isBooking)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
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

class _TimeSlotGrid extends StatelessWidget {
  const _TimeSlotGrid({
    required this.slots,
    required this.selectedSlot,
    required this.onSelected,
    this.unavailableSlots = const {},
  });

  final List<String> slots;
  final String? selectedSlot;
  final ValueChanged<String> onSelected;
  final Set<String> unavailableSlots;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 360
            ? 3
            : constraints.maxWidth >= 250
            ? 2
            : 1;
        final spacing = columns == 3 ? 10.0 : 12.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: slots.map((slot) {
            final isUnavailable = unavailableSlots.contains(slot);
            return SizedBox(
              width: itemWidth,
              height: 48,
              child: _TimeSlotButton(
                label: slot,
                isSelected: selectedSlot == slot,
                isUnavailable: isUnavailable,
                onTap: isUnavailable ? null : () => onSelected(slot),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _TimeSlotButton extends StatelessWidget {
  const _TimeSlotButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isUnavailable = false,
  });

  final String label;
  final bool isSelected;
  final bool isUnavailable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: !isUnavailable,
      child: Material(
        color: isUnavailable
            ? const Color(0xFFF0F0F0)
            : (isSelected ? const Color(0xFF006B2D) : Colors.white),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isUnavailable
                    ? const Color(0xFFD0D0D0)
                    : isSelected
                    ? const Color(0xFF006B2D)
                    : const Color(0xFF62B36E),
                width: isSelected ? 0 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    isUnavailable ? "$label (Full)" : label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isUnavailable
                          ? const Color(0xFF9E9E9E)
                          : (isSelected
                                ? Colors.white
                                : const Color(0xFF006B2D)),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.check,
                      color: Color(0xFF006B2D),
                      size: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
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
/// only the [location]'s active clinic weekdays.
List<_DayOption> _buildVisibleWeekDays(DateTime today, String? location) {
  if (location == null) return [];
  final oneMonthOut = DateTime(today.year, today.month + 1, today.day);
  final days = <_DayOption>[];
  var day = today;
  while (!day.isAfter(oneMonthOut)) {
    if (isDateValidForLocation(location, day)) {
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

/// Parses a slot start time like "9:00am - 9:30am" into (hour, minute).
(int, int)? _parseSlotStartTime(String timeSlot) {
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

String _formatScheduleDate(DateTime date) {
  return "${_monthNames[date.month - 1]} ${date.day}, ${date.year}";
}
