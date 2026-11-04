import 'package:flutter/material.dart';

import '../data/location_schedule.dart';
import '../services/navigation_transitions.dart';
import '../widgets/session_info_card.dart';

/* The doctor's and secretary's screen for choosing a clinic and date, used
both to reschedule a patient and to set a follow-up checkup. It looks like
the patient's Reschedule Appointment screen: clinic chips, a row of day
cards, the session card with slots left, and a confirm button. It only
picks; the caller does the booking. */

/// The clinic and day chosen on [StaffSchedulePickerScreen].
typedef StaffScheduleChoice = ({String location, DateTime date});

/// Opens the picker full screen and returns the choice, or null if the
/// staff went back without confirming.
Future<StaffScheduleChoice?> showStaffSchedulePicker(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required String initialLocation,
  DateTime? initialDate,
  int monthsAhead = 3,
  int? excludeAppointmentId,
}) {
  return Navigator.of(context).push<StaffScheduleChoice>(
    smartCareRoute(
      transition: SmartCareTransition.subPage,
      builder: (_) => StaffSchedulePickerScreen(
        title: title,
        confirmLabel: confirmLabel,
        initialLocation: initialLocation,
        initialDate: initialDate,
        monthsAhead: monthsAhead,
        excludeAppointmentId: excludeAppointmentId,
      ),
    ),
  );
}

const List<String> _shortMonthNames = [
  "JAN",
  "FEB",
  "MAR",
  "APR",
  "MAY",
  "JUN",
  "JUL",
  "AUG",
  "SEP",
  "OCT",
  "NOV",
  "DEC",
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

const Color _green = Color(0xFF006B2D);

class StaffSchedulePickerScreen extends StatefulWidget {
  const StaffSchedulePickerScreen({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.initialLocation,
    this.initialDate,
    this.monthsAhead = 3,
    this.excludeAppointmentId,
  });

  final String title;
  final String confirmLabel;
  final String initialLocation;

  /// The day to select first if it's a clinic day; otherwise the next one.
  final DateTime? initialDate;

  /// How far ahead the day cards go.
  final int monthsAhead;

  /// The appointment being rescheduled, so it isn't counted as a taken slot.
  final int? excludeAppointmentId;

  @override
  State<StaffSchedulePickerScreen> createState() =>
      _StaffSchedulePickerScreenState();
}

class _StaffSchedulePickerScreenState extends State<StaffSchedulePickerScreen> {
  late final DateTime _today;
  late String _location;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _location = clinicLocations.contains(widget.initialLocation)
        ? widget.initialLocation
        : clinicLocations.first;
    _selectedDate = _firstDayFrom(widget.initialDate ?? _today);
  }

  /// The clinic days of [_location] from today up to [widget.monthsAhead]
  /// months out, leaving out today if its session already ended.
  List<DateTime> get _days {
    final last = DateTime(
      _today.year,
      _today.month + widget.monthsAhead,
      _today.day,
    );
    final days = <DateTime>[];
    for (var d = _today; !d.isAfter(last); d = _nextDay(d)) {
      if (isDateValidForLocation(_location, d) &&
          !(d == _today && isSessionOver(_location, d))) {
        days.add(d);
      }
    }
    return days;
  }

  /// The first clinic day on or after [from], or null if there is none.
  DateTime? _firstDayFrom(DateTime from) {
    final start = DateTime(from.year, from.month, from.day);
    final days = _days;
    for (final day in days) {
      if (!day.isBefore(start)) return day;
    }
    return days.isEmpty ? null : days.last;
  }

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width > 800;
    final days = _days;
    final selected = _selectedDate;
    final gap = tablet ? 18.0 : 14.0;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F2E4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: tablet ? 24 : 16,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: tablet ? 900 : 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.arrow_back,
                      color: const Color(0xFF1C5D22),
                      size: tablet ? 28 : 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _green,
                        fontSize: tablet ? 26 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(tablet ? 28 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel("Select Location"),
                          const SizedBox(height: 8),
                          _LocationRow(
                            selected: _location,
                            onSelected: (location) => setState(() {
                              _location = location;
                              _selectedDate = _firstDayFrom(
                                _selectedDate ?? _today,
                              );
                            }),
                          ),
                          SizedBox(height: gap),
                          const _SectionLabel("Select Date"),
                          const SizedBox(height: 8),
                          if (days.isEmpty)
                            const Text(
                              "No clinic days available for this location.",
                            )
                          else
                            _DayRow(
                              days: days,
                              selected: selected,
                              onSelected: (day) =>
                                  setState(() => _selectedDate = day),
                            ),
                          if (selected != null) ...[
                            SizedBox(height: gap),
                            const _SectionLabel("Clinic Session"),
                            const SizedBox(height: 8),
                            SessionInfoCard(
                              location: _location,
                              date: selected,
                              excludeAppointmentId: widget.excludeAppointmentId,
                              note:
                                  "Patients are served by queue number. The "
                                  "patient will get the next queue number "
                                  "for this day.",
                            ),
                          ],
                          SizedBox(height: gap),
                          SizedBox(
                            width: double.infinity,
                            height: tablet ? 50 : 48,
                            child: ElevatedButton(
                              onPressed: selected == null
                                  ? null
                                  : () => Navigator.of(context).pop(
                                      (location: _location, date: selected),
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    tablet ? 12 : 8,
                                  ),
                                ),
                              ),
                              child: Text(
                                widget.confirmLabel,
                                style: TextStyle(
                                  fontSize: tablet ? 15 : 14,
                                  fontWeight: FontWeight.bold,
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
    );
  }
}

DateTime _nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: _green,
        fontSize: MediaQuery.sizeOf(context).width > 800 ? 18 : 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width > 800;
    return Row(
      children: [
        for (var i = 0; i < clinicLocations.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: tablet ? 48 : 44,
              child: _LocationChip(
                label: clinicLocations[i],
                isSelected: clinicLocations[i] == selected,
                onTap: () => onSelected(clinicLocations[i]),
              ),
            ),
          ),
        ],
      ],
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
    final tablet = MediaQuery.sizeOf(context).width > 800;
    final fg = isSelected ? Colors.white : _green;
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? _green : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? null
                  : Border.all(color: const Color(0xFF62B36E)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: tablet ? 18 : 16, color: fg),
                SizedBox(width: tablet ? 6 : 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: tablet ? 15 : 13,
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

/// A horizontally scrolling row of day cards (month, weekday, day number).
class _DayRow extends StatefulWidget {
  const _DayRow({
    required this.days,
    required this.selected,
    required this.onSelected,
  });

  final List<DateTime> days;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  @override
  State<_DayRow> createState() => _DayRowState();
}

class _DayRowState extends State<_DayRow> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    // Bring the preselected day into view, e.g. a follow-up a week out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    final index = widget.days.indexWhere((d) => d == widget.selected);
    if (index <= 0 || !_controller.hasClients) return;
    final target = (index * (_itemWidth + _gap) - _gap * 2).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    _controller.jumpTo(target);
  }

  double get _itemWidth =>
      MediaQuery.sizeOf(context).width > 800 ? 76.0 : 54.0;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width > 800;
    return SizedBox(
      height: tablet ? 88 : 72,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        itemCount: widget.days.length,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (context, index) {
          final day = widget.days[index];
          return SizedBox(
            width: _itemWidth,
            child: _DayCard(
              date: day,
              isSelected: day == widget.selected,
              onTap: () => widget.onSelected(day),
            ),
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width > 800;
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? _green : const Color(0xFFF7F9F6),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _shortMonthNames[date.month - 1],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white70
                          : const Color(0xFF6E8D73),
                      fontSize: tablet ? 11 : 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _shortWeekdayNames[date.weekday - 1],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF27943B),
                      fontSize: tablet ? 13 : 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${date.day}",
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: tablet ? 21 : 16,
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
    );
  }
}
