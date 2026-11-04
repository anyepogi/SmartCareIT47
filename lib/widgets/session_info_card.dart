import 'package:flutter/material.dart';

import '../data/location_schedule.dart';
import '../services/appointment/appointment_service.dart';

const List<String> _weekdayNames = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
];

/* Shown on the booking and reschedule screens where the time slot picker
used to be. It shows the clinic hours for the chosen day, a short note
that a late queue number might not be seen before the session ends, and
how many of the session's 25 slots are left. */
class SessionInfoCard extends StatefulWidget {
  const SessionInfoCard({
    super.key,
    required this.location,
    required this.date,
    this.excludeAppointmentId,
    this.note,
  });

  final String location;
  final DateTime date;

  /// The appointment being rescheduled, so it isn't counted as taken.
  final int? excludeAppointmentId;

  /// Replaces the default patient-facing note, e.g. on the staff screens.
  final String? note;

  @override
  State<SessionInfoCard> createState() => _SessionInfoCardState();
}

class _SessionInfoCardState extends State<SessionInfoCard> {
  ({int capacity, int used, int remaining})? _slots;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void didUpdateWidget(covariant SessionInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location ||
        oldWidget.date != widget.date) {
      // build() runs right after this, so no setState needed.
      _slots = null;
      _loadSlots();
    }
  }

  Future<void> _loadSlots() async {
    final location = widget.location;
    final date = widget.date;
    if (location.isEmpty) return;
    final dateKey =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    try {
      final slots = await AppointmentService.getSessionSlots(
        location: location,
        date: dateKey,
        excludeAppointmentId: widget.excludeAppointmentId,
      );
      // Ignore the answer if the patient already picked another day.
      if (!mounted || widget.location != location || widget.date != date) {
        return;
      }
      setState(() => _slots = slots);
    } catch (_) {
      // Leave it hidden. The backend still blocks a full session.
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    final date = widget.date;
    final slots = _slots;
    // Larger text and padding on tablets (wider than 800px).
    final tablet = MediaQuery.sizeOf(context).width > 800;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tablet ? 16 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC7D8C5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: tablet ? 22 : 20,
            backgroundColor: const Color(0xFFD9EED8),
            child: Icon(
              Icons.schedule,
              color: const Color(0xFF006B2D),
              size: tablet ? 22 : 20,
            ),
          ),
          SizedBox(width: tablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_weekdayNames[date.weekday - 1]}, "
                  "${sessionTimeLabel(location) ?? ''}",
                  style: TextStyle(
                    color: const Color(0xFF006B2D),
                    fontSize: tablet ? 15.5 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.note ??
                      "Patients are served by queue number. If your number "
                          "is near the end, you might not be seen before the "
                          "session ends.",
                  style: TextStyle(
                    color: const Color(0xFF404040),
                    fontSize: tablet ? 13.5 : 12,
                    height: tablet ? 1.4 : 1.3,
                  ),
                ),
                if (slots != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    slots.remaining == 0
                        ? "Fully booked (${slots.capacity} of ${slots.capacity}). Please choose another date."
                        : "${slots.remaining} of ${slots.capacity} slots left",
                    style: TextStyle(
                      color: slots.remaining == 0
                          ? const Color(0xFFC41E3A)
                          : slots.remaining <= 5
                          ? const Color(0xFFB45309)
                          : const Color(0xFF006B2D),
                      fontSize: tablet ? 14 : 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
