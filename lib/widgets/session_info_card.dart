import 'package:flutter/material.dart';

import '../data/location_schedule.dart';

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
used to be. It shows the clinic's session hours for the chosen day and
explains that patients get a queue number in the order they book (like
SO1 for the first online booking at Sta. Rita) instead of picking a time. */
class SessionInfoCard extends StatelessWidget {
  const SessionInfoCard({
    super.key,
    required this.location,
    required this.date,
  });

  final String location;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final letter = location.isEmpty ? 'S' : location[0];
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
                  "No need to pick a time. You'll get a queue number based "
                  "on the order you book (for example ${letter}O1 is the "
                  "first online booking), and patients are served in that "
                  "order.",
                  style: TextStyle(
                    color: const Color(0xFF404040),
                    fontSize: tablet ? 13.5 : 12,
                    height: tablet ? 1.4 : 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
