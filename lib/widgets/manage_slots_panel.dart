import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../data/location_schedule.dart';
import '../services/appointment/appointment_service.dart';
import '../services/notifications/appointment_reminder_service.dart';
import '../services/notifications/notification_service.dart';
import '../services/schedule/schedule_service.dart';
import '../state/app_session.dart';

const List<String> _locations = clinicLocations;

/// Returns [from] if it's a valid clinic day for [location], otherwise the
/// nearest later valid day (searching up to two weeks out).
DateTime _nearestValidDate(String location, DateTime from) {
  var day = from;
  for (var i = 0; i < 14; i++) {
    if (isDateValidForLocation(location, day)) return day;
    day = day.add(const Duration(days: 1));
  }
  return from;
}

/// Lets a doctor or secretary block/unblock time slots for a specific
/// date and clinic location. Blocked slots are hidden from patients when
/// they book or reschedule an appointment. Blocking a slot that already
/// has a patient's appointment cancels that appointment and notifies the
/// patient, after the staff member confirms and gives a reason.
class ManageSlotsPanel extends StatefulWidget {
  const ManageSlotsPanel({super.key});

  @override
  State<ManageSlotsPanel> createState() => _ManageSlotsPanelState();
}

class _ManageSlotsPanelState extends State<ManageSlotsPanel> {
  String _location = _locations.first;
  DateTime _date = DateTime.now();
  List<String> get _timeSlots => timeSlotsForLocation(_location);
  Set<String> _blocked = {};
  Map<String, Map<String, dynamic>> _booked = {};
  bool _loading = true;
  String? _error;

  String get _dateKey =>
      "${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}";

  @override
  void initState() {
    super.initState();
    _date = _nearestValidDate(_location, _date);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final details = await ScheduleService.getSlotDetails(
        location: _location,
        date: _dateKey,
      );
      if (!mounted) return;
      setState(() {
        _blocked = details.blockedSlots.toSet();
        _booked = details.bookedSlots;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _toggle(String slot) async {
    final bookedInfo = _booked[slot];
    if (bookedInfo != null) {
      await _confirmBlockBookedSlot(slot, bookedInfo);
      return;
    }

    final wasBlocked = _blocked.contains(slot);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(wasBlocked ? "Unblock this slot?" : "Block this slot?"),
        content: Text(
          wasBlocked
              ? "\"$slot\" will be reopened for patient booking."
              : "\"$slot\" will be closed so patients can't book it.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006B2D),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(wasBlocked ? "Unblock" : "Block"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      wasBlocked ? _blocked.remove(slot) : _blocked.add(slot);
    });
    try {
      await ScheduleService.toggleSlot(
        location: _location,
        date: _dateKey,
        timeSlot: slot,
        userId: SmartCareSession.currentUserId,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        wasBlocked ? _blocked.add(slot) : _blocked.remove(slot);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _confirmBlockBookedSlot(
    String slot,
    Map<String, dynamic> bookedInfo,
  ) async {
    final reasonController = TextEditingController();
    final patientName = bookedInfo['patient_name'] as String? ?? 'Patient';

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Patient Already Scheduled"),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: math.max(
                120,
                MediaQuery.sizeOf(dialogContext).height -
                    MediaQuery.viewInsetsOf(dialogContext).bottom -
                    200,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$patientName has an appointment in this slot ($slot). "
                    "Blocking it will cancel their appointment and notify them.",
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    autofocus: true,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Reason for cancellation",
                      hintText: "e.g. Doctor is unavailable that day",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD9534F),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final text = reasonController.text.trim();
                Navigator.pop(
                  dialogContext,
                  text.isEmpty ? 'No reason provided.' : text,
                );
              },
              child: const Text("Block & Cancel Appointment"),
            ),
          ],
        );
      },
    );

    if (reason == null) return;

    final appointmentId = bookedInfo['appointment_id'] as int;
    final patientUserId = bookedInfo['user_id'] as int;

    try {
      await AppointmentService.cancel(
        appointmentId,
        actorUserId: SmartCareSession.currentUserId,
        reason: reason,
      );
      await AppointmentReminderService.cancelForAppointment(appointmentId);
      await ScheduleService.toggleSlot(
        location: _location,
        date: _dateKey,
        timeSlot: slot,
        userId: SmartCareSession.currentUserId,
      );
      await NotificationService.create(
        userId: patientUserId,
        title: "Appointment Cancelled",
        message:
            "Your appointment on $_dateKey at $slot ($_location) was "
            "cancelled by the clinic. Reason: $reason",
        type: "Alerts",
        targetRoute: "/appointment",
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Slot blocked and $patientName was notified.")),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final initial = _date.isBefore(todayDateOnly)
        ? _nearestValidDate(_location, todayDateOnly)
        : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: todayDateOnly,
      lastDate: todayDateOnly.add(const Duration(days: 365)),
      selectableDayPredicate: (day) => isDateValidForLocation(_location, day),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD5E4D5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Manage Time Slots",
            style: TextStyle(
              color: Color(0xFF1B6F2A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Tap a slot to block or reopen it for patient booking.",
            style: TextStyle(color: Color(0xFF6E8D73), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _locations.map((loc) {
              final selected = loc == _location;
              return ChoiceChip(
                label: Text(loc),
                selected: selected,
                selectedColor: const Color(0xFF006B2D),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF006B2D),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF62B36E)),
                ),
                onSelected: (_) {
                  setState(() {
                    _location = loc;
                    _date = _nearestValidDate(loc, _date);
                  });
                  _load();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF006B2D),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _dateKey,
                  style: const TextStyle(
                    color: Color(0xFF1A3320),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit, color: Color(0xFF6E8D73), size: 14),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF006B2D)),
              ),
            )
          else if (_error != null)
            Column(
              children: [
                Text(_error!, style: const TextStyle(color: Color(0xFF8B2F2F))),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((slot) {
                final bookedInfo = _booked[slot];
                final blocked = _blocked.contains(slot) || bookedInfo != null;
                return InkWell(
                  onTap: () => _toggle(slot),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: blocked
                          ? const Color(0xFFFBE7E7)
                          : const Color(0xFFE9F6EA),
                      border: Border.all(
                        color: blocked
                            ? const Color(0xFFD9534F)
                            : const Color(0xFF16A34A),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          bookedInfo != null
                              ? Icons.person
                              : (blocked ? Icons.block : Icons.check_circle),
                          size: 14,
                          color: blocked
                              ? const Color(0xFFD9534F)
                              : const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          bookedInfo != null
                              ? "$slot (${bookedInfo['patient_name']})"
                              : slot,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: blocked
                                ? const Color(0xFFD9534F)
                                : const Color(0xFF16751F),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
