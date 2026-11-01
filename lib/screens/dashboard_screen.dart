import 'dart:async';

import 'package:flutter/material.dart';

import 'resched.dart';
import '../data/location_schedule.dart';
import '../services/appointment/appointment_service.dart';
import '../services/navigation_transitions.dart';
import '../services/geofence/geofence_service.dart';
import '../services/notifications/appointment_reminder_service.dart';
import '../services/profile/profile_service.dart';
import '../services/queue/queue_service.dart';
import '../state/app_session.dart';
import 'confirm.dart';
import 'cancelled.dart';
import '../widgets/smartcare_dashboard_header.dart';
import '../widgets/smartcare_bottom_nav.dart'
    show SmartCareBottomNav, SmartCareBottomItem, smartCareGoTo;

const List<String> _dashboardMonthNames = [
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

const List<String> _dashboardWeekdayNames = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
];

class _ScheduleSuggestion {
  const _ScheduleSuggestion({required this.date, required this.location});

  final DateTime date;
  final String location;

  String get dateKey =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  String get label {
    final weekday = _dashboardWeekdayNames[date.weekday - 1];
    return "$weekday, ${_dashboardMonthNames[date.month - 1]} ${date.day} "
        "(${sessionTimeLabel(location) ?? ''})";
  }
}

DateTime _nextDateForWeekday(int isoWeekday, {int occurrence = 0}) {
  final now = DateTime.now();
  var date = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(const Duration(days: 1));
  while (date.weekday != isoWeekday) {
    date = date.add(const Duration(days: 1));
  }
  return date.add(Duration(days: 7 * occurrence));
}

/// The [skip]-th upcoming date (0 = nearest) that's actually a valid clinic
/// day for [location]. Used as a fallback when a patient's historically
/// preferred weekday no longer falls on one of the location's active days.
DateTime? _nextValidDateForLocation(String location, {int skip = 0}) {
  var date = DateTime.now().add(const Duration(days: 1));
  var found = 0;
  for (var i = 0; i < 60; i++) {
    if (isDateValidForLocation(location, date)) {
      if (found == skip) return date;
      found++;
    }
    date = date.add(const Duration(days: 1));
  }
  return null;
}

String _formatAppointmentDateTime(String isoDate, String sessionTime) {
  final date = DateTime.tryParse(isoDate);
  if (date == null) return "$isoDate, $sessionTime";
  return "${_dashboardMonthNames[date.month - 1]} ${date.day}, ${date.year}, $sessionTime";
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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isCancelling = false;
  OverlayEntry? _cancellingOverlayEntry;

  Map<String, dynamic>? _upcomingAppointment;
  bool _isLoadingAppointment = true;
  Map<String, dynamic>? _nowServing;

  Map<String, dynamic>? _bookingPattern;
  bool _isBookingSuggestion = false;
  _ScheduleSuggestion? _topSuggestion;
  List<_ScheduleSuggestion> _alternativeSuggestions = [];
  bool _isCheckingSuggestion = false;

  int _totalVisits = 0;

  @override
  void initState() {
    super.initState();
    SmartCareSession.switchRole(UserRole.patient);
    _loadUpcomingAppointment();
    _loadBookingPattern();
    _loadTotalVisits();
    final userId = SmartCareSession.currentUserId;
    if (userId != null) {
      AppointmentReminderService.syncAndShowNewNotifications(userId);
    }
  }

  Future<void> _loadTotalVisits() async {
    final userId = SmartCareSession.currentUserId;
    if (userId == null) return;
    try {
      final visits = await AppointmentService.getVisitHistory(userId: userId);
      if (!mounted) return;
      setState(() => _totalVisits = visits.length);
    } catch (_) {
      // Leave it at 0 if the fetch fails.
    }
  }

  Future<void> _loadBookingPattern() async {
    final userId = SmartCareSession.currentUserId;
    if (userId == null) return;
    try {
      final pattern = await AppointmentService.getBookingPattern(userId);
      if (!mounted) return;
      setState(() => _bookingPattern = pattern);
      await _computeSuggestions();
    } catch (_) {
      // Silently keep the card in its "not enough history" state.
    }
  }

  /// Picks a recommendation based on the patient's historical weekday and
  /// location preferences: the next date on their usual weekday at their
  /// usual clinic, plus the following two as alternatives. There are no
  /// time slots to check anymore, since every booking just gets the next
  /// queue number for that day.
  Future<void> _computeSuggestions() async {
    final pattern = _bookingPattern;
    if (pattern == null || pattern['has_history'] != true) {
      setState(() {
        _topSuggestion = null;
        _alternativeSuggestions = [];
      });
      return;
    }
    final weekdays = pattern['weekdays'] as List;
    final locations = pattern['locations'] as List;
    if (weekdays.isEmpty || locations.isEmpty) {
      setState(() {
        _topSuggestion = null;
        _alternativeSuggestions = [];
      });
      return;
    }

    final weekday = weekdays[0]['weekday'] as int;
    final location = locations[0]['location'] as String;

    // The patient's historically preferred weekday may no longer be one of
    // this location's active clinic days (e.g. old data from before hours
    // were restricted). Use it when it's still valid; otherwise fall back
    // to the location's nearest actual open days so a recommendation can
    // still be made.
    final preferredWeekdayDate = _nextDateForWeekday(weekday);
    final candidateDates =
        isDateValidForLocation(location, preferredWeekdayDate)
        ? List.generate(
            3,
            (occurrence) =>
                _nextDateForWeekday(weekday, occurrence: occurrence),
          )
        : List.generate(
            3,
            (skip) => _nextValidDateForLocation(location, skip: skip),
          ).whereType<DateTime>().toList();

    if (!mounted) return;
    setState(() {
      final suggestions = candidateDates
          .map((date) => _ScheduleSuggestion(date: date, location: location))
          .toList();
      _topSuggestion = suggestions.isEmpty ? null : suggestions.first;
      _alternativeSuggestions = suggestions.skip(1).toList();
      _isCheckingSuggestion = false;
    });
  }

  Future<void> _bookSuggestion(_ScheduleSuggestion suggestion) async {
    if (_isBookingSuggestion) return;
    setState(() => _isBookingSuggestion = true);
    try {
      final booking = await AppointmentService.book(
        userId: SmartCareSession.currentUserId ?? 0,
        location: suggestion.location,
        date: suggestion.dateKey,
      );
      if (!mounted) return;
      _showMessage(
        "Appointment booked for ${suggestion.label}. Your queue number is "
        "${booking.queueCode}.",
      );
      await _loadUpcomingAppointment();
      await _computeSuggestions();
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
      await _computeSuggestions();
    } finally {
      if (mounted) {
        setState(() => _isBookingSuggestion = false);
      }
    }
  }

  void _showAlternativeSuggestions() {
    final alternatives = _alternativeSuggestions;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Alternative Times"),
        content: alternatives.isEmpty
            ? const Text("No close alternatives available right now.")
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final alt in alternatives)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.schedule,
                        color: Color(0xFF5C28D6),
                      ),
                      title: Text(
                        alt.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(alt.location),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _bookSuggestion(alt);
                      },
                    ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadUpcomingAppointment() async {
    final userId = SmartCareSession.currentUserId;
    if (userId == null) {
      setState(() => _isLoadingAppointment = false);
      return;
    }

    setState(() => _isLoadingAppointment = true);
    try {
      final appt = await AppointmentService.getUpcoming(userId);
      if (!mounted) return;
      setState(() {
        _upcomingAppointment = appt;
        _isLoadingAppointment = false;
      });
      if (appt != null) {
        AppointmentReminderService.scheduleForAppointment(appt);
        AppointmentReminderService.checkAndNotifyIfDue(
          userId: userId,
          appointment: appt,
        );
        _loadNowServing(appt['location'] as String);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingAppointment = false);
    }
  }

  Future<void> _loadNowServing(String location) async {
    try {
      final nowServing = await QueueService.getNowServing(location);
      if (!mounted) return;
      setState(() => _nowServing = nowServing);
    } catch (_) {
      // Keep the "no one currently serving" fallback state.
    }
  }

  /// The patient's queue number, like SO3.
  String get _queueNumberValue {
    final appointment = _upcomingAppointment;
    if (appointment == null) return "--";
    final label = appointmentQueueLabel(appointment);
    return label.isEmpty ? "--" : label;
  }

  /// The queue number being served now at the patient's clinic, out of
  /// how many queue numbers that clinic has given out today, like SW2/5.
  String get _nowServingValue => nowServingLabel(
    _nowServing,
    (_nowServing?['total_in_session'] as num?)?.toInt(),
  );

  String get _queueDateDetail {
    final date = _upcomingAppointment?['schedule_date'] as String?;
    if (date == null) return "No appointment";
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    final weekday = _dashboardWeekdayNames[parsed.weekday - 1];
    return "$weekday, ${_dashboardMonthNames[parsed.month - 1]} ${parsed.day}, ${parsed.year}";
  }

  void _showQueueNumberInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF16751F)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "How Your Queue Number Works",
                style: TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          "Your queue number is the last 2 digits of your Appointment "
          "ID/Reference Number.\n\n"
          "Example: STR26072508 → Queue # 08\n\n"
          "The date shown below your queue number is when that "
          "appointment/queue number is for: $_queueDateDetail.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCancellingOverlay() {
    if (_cancellingOverlayEntry != null) {
      return;
    }

    _cancellingOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Material(
            color: Colors.black.withOpacity(0.5),
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
                    "Cancelling your appointment...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_cancellingOverlayEntry!);
  }

  void _hideCancellingOverlay() {
    _cancellingOverlayEntry?.remove();
    _cancellingOverlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return SmartCareDashboardBackGuard(
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F2E4),
        bottomNavigationBar: const SmartCareBottomNav(
          currentItem: SmartCareBottomItem.home,
          roleOverride: UserRole.patient,
        ),
        body: Stack(
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final isTablet = _isTablet(context);
                  final horizontalPadding = isTablet
                      ? 24.0
                      : constraints.maxWidth < 380
                      ? 12.0
                      : 16.0;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        const _DashboardHeader(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            14,
                            horizontalPadding,
                            24,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isTablet ? 1080 : 760,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _StatGrid(
                                    stats: [
                                      _DashboardStat(
                                        icon: Icons.medical_services,
                                        value: _nowServingValue,
                                        label: "Now Serving",
                                        detail: "Patient with doctor",
                                        iconBackground: const Color(0xFFE5F4ED),
                                        iconColor: const Color(0xFF128049),
                                        onTap: () {
                                          smartCareGoTo(context, '/queue');
                                        },
                                      ),
                                      _DashboardStat(
                                        icon: Icons.groups,
                                        value: _queueNumberValue,
                                        label: "Queue #",
                                        detail: _queueDateDetail,
                                        iconBackground: const Color(0xFFE0F4E1),
                                        iconColor: const Color(0xFF16751F),
                                        onTap: () {
                                          smartCareGoTo(context, '/queue');
                                        },
                                        onInfoTap: () {
                                          _showQueueNumberInfo(context);
                                        },
                                      ),
                                      _DashboardStat(
                                        icon: Icons.calendar_month,
                                        value: "$_totalVisits",
                                        label: "Total Visits",
                                        detail: "All-time completed",
                                        iconBackground: const Color(0xFFE7F6EA),
                                        iconColor: const Color(0xFF1E8D3E),
                                        onTap: () {
                                          smartCareGoTo(context, '/visits');
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  _SectionTitle(
                                    title: "Upcoming Appointment",
                                    onViewAll: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/upcoming-appointments',
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  if (_isLoadingAppointment)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF006B2D),
                                        ),
                                      ),
                                    )
                                  else if (_upcomingAppointment == null)
                                    _NoUpcomingAppointmentCard(
                                      onBook: () => smartCareGoTo(
                                        context,
                                        '/appointment',
                                      ),
                                    )
                                  else
                                    _UpcomingAppointmentCard(
                                      location:
                                          _upcomingAppointment!['location']
                                              as String,
                                      status:
                                          _upcomingAppointment!['status']
                                              as String?,
                                      dateTimeText: _formatAppointmentDateTime(
                                        _upcomingAppointment!['schedule_date']
                                            as String,
                                        appointmentTimeLabel(
                                          _upcomingAppointment!,
                                        ),
                                      ),
                                      onViewDetails: () async {
                                        final patientName =
                                            await _currentPatientName();
                                        if (!context.mounted) return;
                                        Navigator.push(
                                          context,
                                          smartCareRoute(
                                            transition:
                                                SmartCareTransition.subPage,
                                            builder: (_) => AppointmentConfirmScreen(
                                              dateTime: _formatAppointmentDateTime(
                                                _upcomingAppointment!['schedule_date']
                                                    as String,
                                                appointmentTimeLabel(
                                                  _upcomingAppointment!,
                                                ),
                                              ),
                                              patientName: patientName,
                                              appointmentId:
                                                  _upcomingAppointment!['reference_no']
                                                      as String? ??
                                                  '',
                                              location:
                                                  _upcomingAppointment!['location']
                                                      as String,
                                              queueCode:
                                                  _upcomingAppointment!['queue_code']
                                                      as String?,
                                              isExistingView: true,
                                            ),
                                          ),
                                        );
                                      },
                                      onReschedule: () {
                                        Navigator.push(
                                          context,
                                          smartCareRoute(
                                            transition:
                                                SmartCareTransition.subPage,
                                            builder: (_) =>
                                                AppointmentBookingScreen(
                                                  existingAppointmentId:
                                                      _upcomingAppointment!['appointment_id']
                                                          as int,
                                                ),
                                          ),
                                        );
                                      },
                                      onCancel: () {
                                        showDialog<void>(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (dialogContext) {
                                            return Dialog(
                                              backgroundColor:
                                                  Colors.transparent,
                                              insetPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 24,
                                                  ),
                                              child: Center(
                                                child: ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxWidth: 440,
                                                      ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            28,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.15,
                                                              ),
                                                          blurRadius: 24,
                                                          offset: const Offset(
                                                            0,
                                                            12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    padding:
                                                        const EdgeInsets.fromLTRB(
                                                          20,
                                                          18,
                                                          20,
                                                          20,
                                                        ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 70,
                                                          height: 70,
                                                          decoration:
                                                              BoxDecoration(
                                                                color:
                                                                    const Color(
                                                                      0xFFFFEBEE,
                                                                    ),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                          child: const Icon(
                                                            Icons.event_busy,
                                                            color: Color(
                                                              0xFFD32F2F,
                                                            ),
                                                            size: 36,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        const Text(
                                                          "Cancel Appointment?",
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            color: Color(
                                                              0xFF1A3320,
                                                            ),
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        const Text(
                                                          "Are you sure you want to cancel this appointment? This action cannot be undone.",
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Color(
                                                              0xFF666666,
                                                            ),
                                                            height: 1.5,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 20,
                                                        ),
                                                        Container(
                                                          width:
                                                              double.infinity,
                                                          decoration: BoxDecoration(
                                                            color: const Color(
                                                              0xFFF9FAFB,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                      0.04,
                                                                    ),
                                                                blurRadius: 16,
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      6,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                          padding:
                                                              const EdgeInsets.all(
                                                                18,
                                                              ),
                                                          child: Column(
                                                            children: [
                                                              _DialogDetailRow(
                                                                icon: Icons
                                                                    .calendar_today,
                                                                title:
                                                                    "Date & Time",
                                                                value:
                                                                    _upcomingAppointment ==
                                                                        null
                                                                    ? ''
                                                                    : _formatAppointmentDateTime(
                                                                        _upcomingAppointment!['schedule_date']
                                                                            as String,
                                                                        appointmentTimeLabel(
                                                                          _upcomingAppointment!,
                                                                        ),
                                                                      ),
                                                              ),
                                                              const SizedBox(
                                                                height: 14,
                                                              ),
                                                              _DialogDetailRow(
                                                                icon: Icons
                                                                    .location_on,
                                                                title: "Clinic",
                                                                value:
                                                                    _upcomingAppointment ==
                                                                        null
                                                                    ? ''
                                                                    : _upcomingAppointment!['location']
                                                                          as String,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 22,
                                                        ),
                                                        SizedBox(
                                                          width:
                                                              double.infinity,
                                                          height: 48,
                                                          child: ElevatedButton(
                                                            onPressed: () async {
                                                              final appointmentId =
                                                                  _upcomingAppointment?['appointment_id']
                                                                      as int?;
                                                              final cancelledDateTime =
                                                                  _upcomingAppointment ==
                                                                      null
                                                                  ? ''
                                                                  : _formatAppointmentDateTime(
                                                                      _upcomingAppointment!['schedule_date']
                                                                          as String,
                                                                      appointmentTimeLabel(
                                                                        _upcomingAppointment!,
                                                                      ),
                                                                    );
                                                              final cancelledRef =
                                                                  _upcomingAppointment?['reference_no']
                                                                      as String? ??
                                                                  '';
                                                              Navigator.pop(
                                                                dialogContext,
                                                              );
                                                              if (!mounted ||
                                                                  appointmentId ==
                                                                      null) {
                                                                return;
                                                              }
                                                              setState(() {
                                                                _isCancelling =
                                                                    true;
                                                              });
                                                              _showCancellingOverlay();
                                                              // The backend can refuse, for
                                                              // example when the secretary just
                                                              // sent the patient to the doctor.
                                                              String?
                                                              cancelError;
                                                              try {
                                                                await AppointmentService.cancel(
                                                                  appointmentId,
                                                                );
                                                                await AppointmentReminderService.cancelForAppointment(
                                                                  appointmentId,
                                                                );
                                                              } catch (e) {
                                                                cancelError = e
                                                                    .toString()
                                                                    .replaceFirst(
                                                                      'Exception: ',
                                                                      '',
                                                                    );
                                                              }
                                                              if (!mounted) {
                                                                _hideCancellingOverlay();
                                                                return;
                                                              }
                                                              _hideCancellingOverlay();
                                                              setState(() {
                                                                _isCancelling =
                                                                    false;
                                                              });
                                                              await _loadUpcomingAppointment();
                                                              if (!mounted) {
                                                                return;
                                                              }
                                                              // Not cancelled: show why and
                                                              // stay on the dashboard instead
                                                              // of the "Appointment Cancelled!"
                                                              // screen.
                                                              if (cancelError !=
                                                                  null) {
                                                                if (!context
                                                                    .mounted) {
                                                                  return;
                                                                }
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      cancelError,
                                                                    ),
                                                                  ),
                                                                );
                                                                return;
                                                              }
                                                              final cancelledPatientName =
                                                                  await _currentPatientName();
                                                              if (!context
                                                                  .mounted) {
                                                                return;
                                                              }
                                                              Navigator.pushReplacement(
                                                                context,
                                                                smartCareRoute(
                                                                  transition:
                                                                      SmartCareTransition
                                                                          .subPage,
                                                                  builder: (_) => AppointmentCancelledScreen(
                                                                    dateTime:
                                                                        cancelledDateTime,
                                                                    patientName:
                                                                        cancelledPatientName,
                                                                    appointmentId:
                                                                        cancelledRef,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  const Color(
                                                                    0xFFD32F2F,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      14,
                                                                    ),
                                                              ),
                                                            ),
                                                            child: const Text(
                                                              "Cancel Appointment",
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        SizedBox(
                                                          width:
                                                              double.infinity,
                                                          height: 48,
                                                          child: OutlinedButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                dialogContext,
                                                              );
                                                            },
                                                            style: OutlinedButton.styleFrom(
                                                              side: const BorderSide(
                                                                color: Color(
                                                                  0xFFE0E0E0,
                                                                ),
                                                                width: 1,
                                                              ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      14,
                                                                    ),
                                                              ),
                                                            ),
                                                            child: const Text(
                                                              "Keep Appointment",
                                                              style: TextStyle(
                                                                color: Color(
                                                                  0xFF1A3320,
                                                                ),
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  const SizedBox(height: 16),
                                  Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        smartCareGoTo(context, '/chatbot');
                                      },
                                      child: _AiRecommendationCard(
                                        suggestion: _topSuggestion,
                                        isBooking: _isBookingSuggestion,
                                        isChecking: _isCheckingSuggestion,
                                        onAccept: () {
                                          final suggestion = _topSuggestion;
                                          if (suggestion != null) {
                                            _bookSuggestion(suggestion);
                                          }
                                        },
                                        onAlternatives: () {
                                          _showAlternativeSuggestions();
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const _SectionTitle(
                                    title: "Doctor Availability",
                                  ),
                                  const SizedBox(height: 8),
                                  _DoctorAvailabilityCard(
                                    onRefresh: () {
                                      _showMessage(
                                        "Doctor availability refreshed.",
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  const _SectionTitle(title: "Quick Actions"),
                                  const SizedBox(height: 8),
                                  _QuickActionGrid(
                                    actions: [
                                      _DashboardAction(
                                        icon: Icons.event_available,
                                        label: "Book Appointment",
                                        iconColor: const Color(0xFF147C28),
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          200,
                                          226,
                                          186,
                                        ),
                                        onPressed: () {
                                          smartCareGoTo(
                                            context,
                                            '/appointment',
                                          );
                                        },
                                      ),
                                      _DashboardAction(
                                        icon: Icons.assignment_turned_in,
                                        label: "Queue Status",
                                        iconColor: const Color.fromARGB(
                                          255,
                                          74,
                                          189,
                                          246,
                                        ),
                                        backgroundColor: const Color.from(
                                          alpha: 1,
                                          red: 0.769,
                                          green: 0.91,
                                          blue: 0.906,
                                        ),
                                        onPressed: () {
                                          smartCareGoTo(context, '/queue');
                                        },
                                      ),
                                      _DashboardAction(
                                        icon: Icons.person,
                                        label: "Profile Settings",
                                        iconColor: const Color(0xFFFF8B00),
                                        backgroundColor: const Color(
                                          0xFFFFF1E3,
                                        ),
                                        onPressed: () {
                                          smartCareGoTo(context, '/profile');
                                        },
                                      ),
                                      _DashboardAction(
                                        icon: Icons.notifications,
                                        label: "Notification",
                                        iconColor: const Color.fromARGB(
                                          255,
                                          245,
                                          106,
                                          109,
                                        ),
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          244,
                                          226,
                                          228,
                                        ),
                                        onPressed: () {
                                          smartCareGoTo(
                                            context,
                                            '/notifications',
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final firstName = SmartCareSession.currentUserFirstName;
    final greeting = timeOfDayGreeting();
    final title = (firstName != null && firstName.isNotEmpty)
        ? "$greeting, $firstName!"
        : "$greeting!";
    return SmartCareDashboardHeader(
      title: title,
      subtitle: "Here's your health overview today.",
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final List<_DashboardStat> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        stats.length,
        (index) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: stats[index],
          ),
        ),
      ),
    );
  }
}

class _DashboardStat extends StatelessWidget {
  const _DashboardStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.detail,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
    this.onInfoTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final String detail;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback? onInfoTap;

  /// The "!" button next to the Queue # label.
  Widget _infoButton() {
    return InkWell(
      onTap: onInfoTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFF16751F),
          shape: BoxShape.circle,
        ),
        child: const Text(
          "!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }

  /// Tablet card: 110px tall, icon on the left, text stacked on the right.
  Widget _buildTablet() {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD2E7D1)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: iconBackground,
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF16751F),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1A3320),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (onInfoTap != null) ...[
                        const SizedBox(width: 6),
                        _infoButton(),
                      ],
                    ],
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6E8D73),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isTablet(context)) return _buildTablet();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(minHeight: 75),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD2E7D1)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: iconBackground,
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 8),
            // Shrinks long values like "SO12/30" to fit instead of cutting
            // them off.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF16751F),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF1A3320),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onInfoTap != null) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onInfoTap,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 14,
                      height: 14,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16751F),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        "!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6E8D73), fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF1B6F2A),
            fontSize: _isTablet(context) ? 22 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              "View All",
              style: TextStyle(
                color: const Color(0xFF16751F),
                fontSize: _isTablet(context) ? 15 : 13,
                // Regular weight on tablets; phones keep it bold.
                fontWeight: _isTablet(context)
                    ? FontWeight.normal
                    : FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _NoUpcomingAppointmentCard extends StatelessWidget {
  const _NoUpcomingAppointmentCard({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final tablet = _isTablet(context);
    return Container(
      width: double.infinity,
      padding: tablet
          ? const EdgeInsets.symmetric(horizontal: 24, vertical: 24)
          : const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          CircleAvatar(
            radius: tablet ? 30 : 24,
            backgroundColor: const Color(0xFFDDF6DD),
            child: Icon(
              Icons.event_busy,
              color: const Color(0xFF16751F),
              size: tablet ? 32 : 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "No Upcoming Appointment",
            style: TextStyle(
              color: const Color(0xFF1A3320),
              fontWeight: FontWeight.bold,
              fontSize: tablet ? 18 : 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "You don't have any appointment booked yet.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF506D54),
              fontSize: tablet ? 15 : 12,
            ),
          ),
          SizedBox(height: tablet ? 18 : 14),
          SizedBox(
            width: double.infinity,
            child: _SolidActionButton(
              label: "Book Now",
              onPressed: onBook,
              tall: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingAppointmentCard extends StatelessWidget {
  const _UpcomingAppointmentCard({
    required this.location,
    required this.status,
    required this.dateTimeText,
    required this.onViewDetails,
    required this.onReschedule,
    required this.onCancel,
  });

  final String location;

  /// The appointment's status. Once it is sent_to_doctor or serving, the
  /// Reschedule and Cancel buttons are hidden.
  final String? status;
  final String dateTimeText;
  final VoidCallback onViewDetails;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final withDoctor = isAppointmentWithDoctor({'status': status});
    final tablet = _isTablet(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tablet ? 20 : 12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFDDF6DD),
                child: Icon(
                  Icons.event_available,
                  color: Color(0xFF16751F),
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dr. John Carlo A. Camagay",
                      style: TextStyle(
                        color: const Color(0xFF1A3320),
                        fontWeight: FontWeight.bold,
                        fontSize: tablet ? 18 : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AppointmentMeta(
                      icon: Icons.calendar_today,
                      text: dateTimeText,
                    ),
                    const SizedBox(height: 5),
                    _AppointmentMeta(icon: Icons.location_on, text: location),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(
                label: status == 'serving'
                    ? "With Doctor"
                    : status == 'sent_to_doctor'
                    ? "Sent to Doctor"
                    : "Confirmed",
                color: const Color(0xFFDDF6DD),
                textColor: const Color(0xFF16751F),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SolidActionButton(
                  label: "View Details",
                  onPressed: onViewDetails,
                ),
              ),
              if (!withDoctor) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _OutlineActionButton(
                    label: "Reschedule",
                    borderColor: const Color(0xFF16751F),
                    textColor: const Color(0xFF16751F),
                    onPressed: onReschedule,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OutlineActionButton(
                    label: "Cancel",
                    borderColor: const Color(0xFFFF4B4B),
                    textColor: const Color(0xFFE83232),
                    onPressed: onCancel,
                  ),
                ),
              ],
            ],
          ),
          if (withDoctor) ...[
            const SizedBox(height: 8),
            const Text(
              "You're already with the doctor, so this appointment can't be "
              "rescheduled or cancelled. Please talk to the clinic staff.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF506D54), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppointmentMeta extends StatelessWidget {
  const _AppointmentMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF506D54),
          size: _isTablet(context) ? 17 : 14,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF506D54),
              fontSize: _isTablet(context) ? 14 : 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _AiRecommendationCard extends StatelessWidget {
  const _AiRecommendationCard({
    required this.onAccept,
    required this.onAlternatives,
    this.suggestion,
    this.isBooking = false,
    this.isChecking = false,
  });

  final _ScheduleSuggestion? suggestion;
  final bool isBooking;
  final bool isChecking;
  final VoidCallback onAccept;
  final VoidCallback onAlternatives;

  @override
  Widget build(BuildContext context) {
    final tablet = _isTablet(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tablet ? 20 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3FF),
        border: Border.all(color: const Color(0xFFE2D2FF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: const Color(0xFF5C28D6),
                size: tablet ? 24 : 18,
              ),
              const SizedBox(width: 7),
              Text(
                "AI Schedule Recommendation",
                style: TextStyle(
                  color: const Color(0xFF5C28D6),
                  fontSize: tablet ? 22 : 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE8DFFF)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFEDE3FF),
                  child: Icon(
                    Icons.calendar_month,
                    color: Color(0xFF5C28D6),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Recommended for you",
                        style: TextStyle(
                          color: const Color(0xFF6E8D73),
                          fontSize: tablet ? 13 : 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        suggestion?.label ??
                            (isChecking
                                ? "Checking availability..."
                                : "Book a few appointments so we can learn "
                                      "your preferred day, time, and location."),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF5C28D6),
                          fontWeight: FontWeight.bold,
                          fontSize: tablet ? 18 : 14,
                        ),
                      ),
                      if (suggestion != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          suggestion!.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF506D54),
                            fontSize: tablet ? 13 : 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PurpleActionButton(
                  label: isBooking ? "Booking..." : "Accept",
                  onPressed: (suggestion == null || isBooking)
                      ? null
                      : onAccept,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PurpleOutlineButton(
                  label: "View Alternatives",
                  onPressed: suggestion == null ? null : onAlternatives,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoctorAvailabilityCard extends StatefulWidget {
  const _DoctorAvailabilityCard({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  State<_DoctorAvailabilityCard> createState() =>
      _DoctorAvailabilityCardState();
}

class _DoctorAvailabilityCardState extends State<_DoctorAvailabilityCard> {
  DoctorAvailability? _availability;
  bool _isLoading = true;

  /// Re-fetches the status every 15 seconds, so the patient sees within a
  /// few seconds when the doctor picks a clinic, starts heading there, or
  /// arrives, without having to tap refresh. The query is small, so this
  /// is light on the server.
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadStatus(showSpinner: false),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _isLoading = true);
    try {
      final availability = await GeofenceService.getStatus();
      if (!mounted) return;
      setState(() {
        _availability = availability;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _refresh() {
    widget.onRefresh();
    _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    final clinics = _availability?.clinics.values ?? const [];
    final inClinic = clinics
        .where((c) => c.presence == ClinicPresence.inClinic)
        .firstOrNull;
    final onTheWay = clinics
        .where((c) => c.presence == ClinicPresence.onTheWay)
        .firstOrNull;
    final doctorName = _availability == null
        ? "Doctor"
        : "Dr. ${_availability!.doctorName}";
    final (headerColor, headerText) = inClinic != null
        ? (
            _presenceColor(ClinicPresence.inClinic),
            "In Clinic · ${inClinic.location}",
          )
        : onTheWay != null
        ? (
            _presenceColor(ClinicPresence.onTheWay),
            "On the way to ${onTheWay.location}",
          )
        : (_presenceColor(ClinicPresence.notInClinic), "Not in Clinic");

    final tablet = _isTablet(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tablet ? 20 : 12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor info section
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFDDF6DD),
                child: Icon(Icons.person, color: Color(0xFF16751F), size: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: TextStyle(
                        color: const Color(0xFF1A3320),
                        fontWeight: FontWeight.bold,
                        fontSize: tablet ? 18 : 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _AvailabilityStatus(color: headerColor, text: headerText),
                  ],
                ),
              ),
              IconButton(
                onPressed: _refresh,
                icon: const Icon(
                  Icons.refresh,
                  color: Color(0xFF16751F),
                  size: 20,
                ),
                tooltip: "Refresh",
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE3EFE1)),
          const SizedBox(height: 8),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF16751F),
                  ),
                ),
              ),
            )
          else
            // Branch list - one branch per row
            Column(
              children: [
                for (final branch in clinicLocations) ...[
                  _BranchListItem(
                    branch: branch,
                    availability: _availability?.clinics[branch],
                  ),
                  if (branch != clinicLocations.last) const SizedBox(height: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _AvailabilityStatus extends StatelessWidget {
  const _AvailabilityStatus({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: const Color(0xFF16751F),
            fontSize: _isTablet(context) ? 14 : 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// "8 min", "1 hr 15 min".
String _formatEta(int minutes) {
  if (minutes < 60) return "$minutes min";
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? "$hours hr" : "$hours hr $rest min";
}

Color _presenceColor(ClinicPresence presence) => switch (presence) {
  ClinicPresence.inClinic => const Color(0xFF0DA94C),
  ClinicPresence.onTheWay => const Color(0xFF1E88E5),
  ClinicPresence.notInClinic => const Color(0xFFFF9800),
};

class _BranchListItem extends StatelessWidget {
  const _BranchListItem({required this.branch, required this.availability});

  final String branch;
  final ClinicAvailability? availability;

  @override
  Widget build(BuildContext context) {
    final presence = availability?.presence ?? ClinicPresence.notInClinic;
    final statusColor = _presenceColor(presence);
    final eta = availability?.etaMinutes;
    final statusText = switch (presence) {
      ClinicPresence.inClinic => "In Clinic",
      ClinicPresence.onTheWay => "On the way",
      ClinicPresence.notInClinic => "Not in Clinic",
    };
    final etaText = presence == ClinicPresence.onTheWay && eta != null
        ? "ETA ${_formatEta(eta)}"
        : null;
    final tablet = _isTablet(context);

    return Container(
      width: double.infinity,
      padding: tablet
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD2E7D1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFF506D54), size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch,
                  style: TextStyle(
                    color: const Color(0xFF1A3320),
                    fontSize: tablet ? 15 : 13,
                    fontWeight: tablet ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (etaText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    etaText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: tablet ? 13 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (presence == ClinicPresence.onTheWay)
                Icon(Icons.directions_car, color: statusColor, size: 14)
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 5),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: tablet ? 13 : 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions});

  final List<_DashboardAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = 2;
        final tablet = _isTablet(context);
        final spacing = tablet ? 16.0 : 12.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: tablet ? 16 : 10,
          children: actions.map((action) {
            return SizedBox(
              width: itemWidth,
              height: tablet ? 96 : 82,
              child: _QuickActionTile(action: action),
            );
          }).toList(),
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _DashboardAction action;

  /// Tablet tile: icon badge on the left, label beside it.
  Widget _buildTablet() {
    return Material(
      color: action.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: action.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: action.iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isTablet(context)) return _buildTablet();

    return Material(
      color: action.backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: action.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: action.iconColor, size: 28),
              const SizedBox(height: 7),
              Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1A3320),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final tablet = _isTablet(context);
    return Container(
      height: tablet ? 30 : 24,
      constraints: BoxConstraints(minWidth: tablet ? 96 : 78),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: textColor,
            fontSize: tablet ? 13 : 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SolidActionButton extends StatelessWidget {
  const _SolidActionButton({
    required this.label,
    required this.onPressed,
    this.tall = false,
  });

  final String label;
  final VoidCallback onPressed;

  /// Uses the bigger 50px tablet size (for "Book Now").
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final tablet = _isTablet(context);
    return SizedBox(
      height: tablet ? (tall ? 50 : 46) : 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16751F),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tablet ? 12 : 8),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: tablet ? (tall ? 16 : 14) : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.borderColor,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tablet = _isTablet(context);
    return SizedBox(
      height: tablet ? 46 : 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: tablet ? 14 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _PurpleActionButton extends StatelessWidget {
  const _PurpleActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tablet = _isTablet(context);
    return SizedBox(
      height: tablet ? 46 : 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5C28D6),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: tablet ? 14 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _PurpleOutlineButton extends StatelessWidget {
  const _PurpleOutlineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tablet = _isTablet(context);
    return SizedBox(
      height: tablet ? 46 : 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF5C28D6),
          side: const BorderSide(color: Color(0xFF7E50DD)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "View Alternatives",
            style: TextStyle(
              fontSize: tablet ? 14 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogDetailRow extends StatelessWidget {
  const _DialogDetailRow({
    required this.icon,
    required this.title,
    required this.value,
  }) : iconColor = const Color(0xFF16751F);

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 238, 228, 242),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF6D6D6D), fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1A3320),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardAction {
  const _DashboardAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onPressed;
}

/// Tablet/desktop layouts (wider than 800px) get the tablet background, a
/// 1080px column and larger text; phones keep their original layout.
bool _isTablet(BuildContext context) => MediaQuery.sizeOf(context).width > 800;

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    border: Border.all(color: const Color(0xFFD2E7D1)),
    borderRadius: BorderRadius.circular(8),
  );
}
