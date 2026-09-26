import 'package:flutter/material.dart';

import '../data/location_schedule.dart';
import '../services/appointment/appointment_service.dart';
import '../services/notifications/notification_service.dart';
import '../services/queue/queue_service.dart';
import '../services/schedule/schedule_service.dart';
import '../state/app_session.dart';

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

class ServingScreen extends StatefulWidget {
  const ServingScreen({
    super.key,
    required this.appointmentId,
    required this.patientUserId,
    required this.patientName,
    required this.referenceNo,
    required this.timeSlot,
    required this.location,
    required this.status,
    this.waitingPatients = const [],
  });

  final int appointmentId;
  final int patientUserId;
  final String patientName;
  final String referenceNo;
  final String timeSlot;
  final String location;

  /// One of: 'booked', 'sent_to_doctor', 'serving'.
  final String status;

  final List<Map<String, String>> waitingPatients;

  @override
  State<ServingScreen> createState() => _ServingScreenState();
}

class _ServingScreenState extends State<ServingScreen> {
  bool _isWorking = false;

  bool get _isDoctor => SmartCareSession.currentRole == UserRole.doctor;

  Future<void> _sendToDoctor() async {
    await _run(() async {
      await QueueService.sendToDoctor(widget.appointmentId);
      await NotificationService.create(
        userId: widget.patientUserId,
        title: "You're Being Called",
        message:
            "Your appointment (${widget.referenceNo}) is being sent to the "
            "doctor. Please stay nearby.",
        type: "Alerts",
        targetRoute: "/queue",
      );
    });
  }

  Future<void> _confirmReceived() async {
    await _run(() async {
      await QueueService.confirmReceived(widget.appointmentId);
    });
  }

  Future<void> _markComplete() async {
    final wantsFollowUp = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Complete Consultation"),
        content: const Text("Does this patient need a follow-up checkup?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Back"),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("No Follow-up"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16751F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Set Follow-up Date"),
          ),
        ],
      ),
    );
    if (wantsFollowUp == null) return;

    DateTime? followUpDate;
    String? followUpTimeSlot;
    String? followUpLocation;
    if (wantsFollowUp) {
      if (!mounted) return;
      // Same as a regular booking, the follow-up can be at any clinic —
      // not necessarily the one this visit happened at.
      followUpLocation = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text("Follow-up Clinic"),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: clinicLocations.map((location) {
                return ChoiceChip(
                  label: Text(location, style: const TextStyle(fontSize: 12)),
                  selected: location == widget.location,
                  onSelected: (_) => Navigator.pop(dialogContext, location),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Back"),
            ),
          ],
        ),
      );
      // If they backed out of the location picker, don't complete at all —
      // they can tap Mark Complete again to retry.
      if (followUpLocation == null) return;

      if (!mounted) return;
      followUpDate = await showDatePicker(
        context: context,
        initialDate: _nearestValidDate(
          followUpLocation,
          DateTime.now().add(const Duration(days: 7)),
        ),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        helpText: "Set a follow-up date",
        selectableDayPredicate: (day) =>
            isDateValidForLocation(followUpLocation!, day),
      );
      // If they backed out of the date picker, don't complete at all —
      // they can tap Mark Complete again to retry.
      if (followUpDate == null) return;

      final followUpDateKey =
          "${followUpDate.year}-${followUpDate.month.toString().padLeft(2, '0')}-${followUpDate.day.toString().padLeft(2, '0')}";

      Set<String> blockedSlots = {};
      try {
        blockedSlots = (await ScheduleService.getBlockedSlots(
          location: followUpLocation,
          date: followUpDateKey,
        )).toSet();
      } catch (_) {
        // If this fails, fall through with nothing pre-blocked — the
        // backend still re-validates availability when the follow-up is
        // actually booked, so this is a UX nicety, not the safety net.
      }

      if (!mounted) return;
      followUpTimeSlot = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text("Follow-up Time"),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: timeSlotsForLocation(followUpLocation!).map((slot) {
                final isBlocked = blockedSlots.contains(slot);
                return ChoiceChip(
                  label: Text(
                    isBlocked ? "$slot (Full)" : slot,
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: false,
                  onSelected: isBlocked
                      ? null
                      : (_) => Navigator.pop(dialogContext, slot),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Back"),
            ),
          ],
        ),
      );
      // Also back out entirely if they didn't pick a time.
      if (followUpTimeSlot == null) return;
    }
    if (!mounted) return;
    if (_isWorking) return;
    setState(() => _isWorking = true);

    try {
      final followUpDateKey = followUpDate == null
          ? null
          : "${followUpDate.year}-${followUpDate.month.toString().padLeft(2, '0')}-${followUpDate.day.toString().padLeft(2, '0')}";
      final followUpWarning = await QueueService.completeAppointment(
        widget.appointmentId,
        followUpDate: followUpDateKey,
        followUpTimeSlot: followUpTimeSlot,
        followUpLocation: followUpLocation,
        actorUserId: SmartCareSession.currentUserId,
      );
      await NotificationService.create(
        userId: widget.patientUserId,
        title: "Consultation Completed",
        message: followUpDate == null || followUpWarning != null
            ? "Your consultation (${widget.referenceNo}) is complete."
            : "Your consultation (${widget.referenceNo}) is complete. "
                  "Please come back on "
                  "${followUpDate.month}/${followUpDate.day}/${followUpDate.year} "
                  "at $followUpTimeSlot ($followUpLocation) for your follow-up.",
        type: "Alerts",
        targetRoute: "/appointment",
      );

      if (!mounted) return;
      if (followUpWarning != null) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("Consultation Completed"),
            content: Text(
              "The visit was marked complete, but the follow-up couldn't "
              "be booked: $followUpWarning",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isWorking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _callAgain() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      await NotificationService.create(
        userId: widget.patientUserId,
        title: "You're Being Called",
        message:
            "Please proceed to the counter now for your appointment "
            "(${widget.referenceNo}).",
        type: "Alerts",
        targetRoute: "/queue",
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${widget.patientName} was notified.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _reschedule() async {
    final result = await showDialog<(DateTime, String)>(
      context: context,
      builder: (dialogContext) => _RescheduleDialog(location: widget.location),
    );
    if (result == null) return;

    final (date, slot) = result;
    final dateKey =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    await _run(() async {
      await AppointmentService.cancel(
        widget.appointmentId,
        actorUserId: SmartCareSession.currentUserId,
        reason: "Rescheduled by the clinic.",
      );
      await AppointmentService.book(
        userId: widget.patientUserId,
        location: widget.location,
        date: dateKey,
        timeSlot: slot,
        isReschedule: true,
        actorUserId: SmartCareSession.currentUserId,
      );
      await NotificationService.create(
        userId: widget.patientUserId,
        title: "Appointment Rescheduled",
        message:
            "Your appointment was rescheduled to $dateKey at $slot "
            "(${widget.location}) by the clinic.",
        type: "Alerts",
        targetRoute: "/appointment",
      );
    });
  }

  Future<void> _cancel() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Cancel Appointment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This will cancel ${widget.patientName}'s appointment and "
              "notify them.",
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Reason for cancellation",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Back"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC41E3A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final text = reasonController.text.trim();
              Navigator.pop(
                dialogContext,
                text.isEmpty ? 'No reason provided.' : text,
              );
            },
            child: const Text("Cancel Appointment"),
          ),
        ],
      ),
    );
    if (reason == null) return;

    await _run(() async {
      await AppointmentService.cancel(
        widget.appointmentId,
        actorUserId: SmartCareSession.currentUserId,
        reason: reason,
      );
      await NotificationService.create(
        userId: widget.patientUserId,
        title: "Appointment Cancelled",
        message:
            "Your appointment (${widget.referenceNo}) was cancelled by the "
            "clinic. Reason: $reason",
        type: "Alerts",
        targetRoute: "/appointment",
      );
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      await action();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isWorking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F2E4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.arrow_back,
                            color: Color(0xFF1C5D22),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFD5E4D5)),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF0F6B2F,
                            ).withValues(alpha: 0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'NOW SERVING',
                            style: TextStyle(
                              color: Color(0xFF16751F),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.patientName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF1A3320),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reference: ${widget.referenceNo}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF506D54),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.timeSlot} • ${widget.location}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF506D54),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildPrimaryAction(),
                          if (widget.status != 'completed') ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionButton(
                                    label: 'CALL AGAIN',
                                    icon: Icons.campaign,
                                    color: const Color(0xFF1F5AA2),
                                    onPressed: _isWorking ? null : _callAgain,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ActionButton(
                                    label: 'RESCHEDULE',
                                    icon: Icons.calendar_month,
                                    color: const Color(0xFFFFA500),
                                    onPressed: _isWorking ? null : _reschedule,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: _ActionButton(
                                label: 'CANCEL',
                                icon: Icons.event_busy,
                                color: const Color(0xFFC41E3A),
                                onPressed: _isWorking ? null : _cancel,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.waitingPatients.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD5E4D5)),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0F6B2F,
                              ).withValues(alpha: 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'WAITING IN LINE',
                                  style: TextStyle(
                                    color: Color(0xFF16751F),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F4E0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '[${widget.waitingPatients.length}]',
                                    style: const TextStyle(
                                      color: Color(0xFF16751F),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildWaitingList(),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryAction() {
    switch (widget.status) {
      case 'booked':
        return SizedBox(
          width: double.infinity,
          child: _ActionButton(
            label: 'SEND TO DOCTOR',
            icon: Icons.arrow_forward,
            color: const Color(0xFF16751F),
            onPressed: _isWorking ? null : _sendToDoctor,
          ),
        );
      case 'sent_to_doctor':
        if (_isDoctor) {
          return SizedBox(
            width: double.infinity,
            child: _ActionButton(
              label: 'CONFIRM RECEIVED',
              icon: Icons.check_circle,
              color: const Color(0xFF16751F),
              onPressed: _isWorking ? null : _confirmReceived,
            ),
          );
        }
        return _statusLabel('Sent to doctor — awaiting confirmation');
      case 'serving':
        if (_isDoctor) {
          return SizedBox(
            width: double.infinity,
            child: _ActionButton(
              label: 'MARK COMPLETE',
              icon: Icons.check_circle,
              color: const Color(0xFF16751F),
              onPressed: _isWorking ? null : _markComplete,
            ),
          );
        }
        return _statusLabel('Currently with the doctor');
      case 'completed':
        return _statusLabel('Consultation completed.');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _statusLabel(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4EF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF506D54),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWaitingList() {
    return Column(
      children: List.generate(widget.waitingPatients.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < widget.waitingPatients.length - 1 ? 12 : 0,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF16751F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.waitingPatients[index]['initials']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.waitingPatients[index]['name']!,
                      style: const TextStyle(
                        color: Color(0xFF1A3320),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.waitingPatients[index]['time']!,
                      style: const TextStyle(
                        color: Color(0xFF506D54),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

const int _rescheduleVisibleMonthCount = 5;

class _MonthOption {
  const _MonthOption(this.year, this.month);

  final int year;
  final int month;

  static const monthNames = [
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

  String get label => monthNames[month - 1];

  bool isSameMonth(DateTime date) => year == date.year && month == date.month;
}

class _RescheduleDialog extends StatefulWidget {
  const _RescheduleDialog({required this.location});

  final String location;

  @override
  State<_RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<_RescheduleDialog> {
  late final DateTime _today;
  late final List<_MonthOption> _months;
  late DateTime _selectedDate;
  String? _slot;
  Set<String> _unavailable = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _months = List.generate(_rescheduleVisibleMonthCount, (index) {
      final monthDate = DateTime(_today.year, _today.month + index);
      return _MonthOption(monthDate.year, monthDate.month);
    });
    _selectedDate = _firstSelectableDateForMonth(_months.first);
    _loadBlockedSlots();
  }

  /// Returns the earliest of [month] that's both selectable (not before
  /// today) and a valid clinic day for [widget.location].
  DateTime _firstSelectableDateForMonth(_MonthOption month) {
    final start = month.isSameMonth(_today)
        ? _today
        : DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    for (var d = start.day; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      if (isDateValidForLocation(widget.location, date)) return date;
    }
    return start;
  }

  List<DateTime> _daysForMonth(_MonthOption month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startDay = month.isSameMonth(_today) ? _today.day : 1;
    final days = <DateTime>[];
    for (var d = startDay; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      if (isDateValidForLocation(widget.location, date)) {
        days.add(date);
      }
    }
    return days;
  }

  Future<void> _loadBlockedSlots() async {
    setState(() {
      _loading = true;
      _slot = null;
    });
    try {
      final dateKey =
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      final blocked = await ScheduleService.getBlockedSlots(
        location: widget.location,
        date: dateKey,
      );
      if (!mounted) return;
      setState(() {
        _unavailable = blocked.toSet();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysForMonth(
      _months.firstWhere((m) => m.isSameMonth(_selectedDate)),
    );

    return AlertDialog(
      title: const Text("Reschedule Appointment"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Month",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _months.map((month) {
                  final selected = month.isSameMonth(_selectedDate);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        month.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedDate = _firstSelectableDateForMonth(month);
                        });
                        _loadBlockedSlots();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Day",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: days.map((day) {
                  final selected =
                      day.year == _selectedDate.year &&
                      day.month == _selectedDate.month &&
                      day.day == _selectedDate.day;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        "${day.day}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedDate = day);
                        _loadBlockedSlots();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Time Slot",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            if (_loading) const LinearProgressIndicator(),
            if (!_loading)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: timeSlotsForLocation(widget.location).map((slot) {
                  final disabled = _unavailable.contains(slot);
                  final selected = _slot == slot;
                  return ChoiceChip(
                    label: Text(slot, style: const TextStyle(fontSize: 11)),
                    selected: selected,
                    onSelected: disabled
                        ? null
                        : (_) => setState(() => _slot = slot),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _slot == null
              ? null
              : () => Navigator.pop(context, (_selectedDate, _slot!)),
          child: const Text("Reschedule"),
        ),
      ],
    );
  }
}
