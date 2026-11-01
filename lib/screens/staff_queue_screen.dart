import 'dart:async';

import 'package:flutter/material.dart';
import '../data/location_schedule.dart';
import '../services/navigation_transitions.dart';
import '../services/notifications/notification_service.dart';
import '../services/queue/queue_service.dart';
import '../state/app_session.dart';
import '../widgets/smartcare_bottom_nav.dart'
    show SmartCareBottomNav, SmartCareBottomItem;
import '../widgets/smartcare_dashboard_header.dart';
import 'serving.dart';
import '../widgets/smartcare_date_picker.dart';

String _queueStatusLabel(String status) {
  switch (status) {
    case 'sent_to_doctor':
      return 'Sent to Doctor';
    case 'serving':
      return 'With Doctor';
    case 'completed':
      return 'Completed';
    case 'no_show':
      return 'No-Show';
    default:
      return 'Waiting';
  }
}

Color _queueStatusColor(String status) {
  switch (status) {
    case 'sent_to_doctor':
      return const Color(0xFF7C3AED);
    case 'serving':
      return const Color(0xFF1F5AA2);
    case 'completed':
      return const Color(0xFF16A34A);
    case 'no_show':
      return const Color(0xFF9CA3AF);
    default:
      return const Color(0xFF6B7280);
  }
}

/* The Queue Management screen shared by the doctor and the secretary.
Both used to have their own copy of this screen that only differed in
the role, so the queue now lives here once and DoctorQueueScreen /
SecretaryQueueScreen just pass in their role. Besides listing the day's
queue, it lets staff filter by clinic, call the next waiting patient
with one tap, and it refreshes itself every few seconds so a status
changed on another phone (for example the doctor confirming a patient)
shows up without leaving the screen. */
class StaffQueueScreen extends StatefulWidget {
  const StaffQueueScreen({super.key, required this.role});

  final UserRole role;

  @override
  State<StaffQueueScreen> createState() => _StaffQueueScreenState();
}

/// Tablet/desktop layouts (wider than 800px) get a centered 1080 container,
/// compact stat cards and larger text; phones keep their layout.
bool _isTablet(BuildContext context) => MediaQuery.sizeOf(context).width > 800;

class _StaffQueueScreenState extends State<StaffQueueScreen> {
  late DateTime _selectedDate;
  bool _showAllQueue = false;
  List<Map<String, dynamic>> _queue = [];
  bool _isLoading = true;
  bool _isCallingNext = false;

  /// The clinic the list is filtered to, or null for every clinic.
  String? _selectedLocation;

  /// Re-fetches the queue every 15 seconds so changes made on another
  /// phone show up here without leaving the screen.
  Timer? _autoRefreshTimer;

  String get _dateKey =>
      "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  /// The first patient still waiting, in time slot order (the backend
  /// already sorts the queue by time).
  Map<String, dynamic>? get _nextWaiting =>
      _queue.where((p) => p['status'] == 'booked').firstOrNull;

  /// True when "All Clinics" is shown and patients are waiting at more
  /// than one clinic. The doctor can only be at one of them, so calling
  /// "the next" patient across clinics could call someone at the wrong
  /// clinic; staff pick the clinic first instead.
  bool get _needsClinicForCallNext =>
      _selectedLocation == null &&
      _queue
              .where((p) => p['status'] == 'booked')
              .map((p) => p['location'])
              .toSet()
              .length >
          1;

  @override
  void initState() {
    super.initState();
    SmartCareSession.switchRole(widget.role);
    _selectedDate = DateTime.now();
    _loadQueue();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadQueue(showSpinner: false),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQueue({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _isLoading = true);
    final dateKey = _dateKey;
    final location = _selectedLocation;
    try {
      final queue = await QueueService.getTodayQueue(
        date: dateKey,
        location: location,
      );
      // Drop the result if the date or clinic changed while it loaded.
      if (!mounted || dateKey != _dateKey || location != _selectedLocation) {
        return;
      }
      setState(() {
        _queue = queue;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      builder: smartCareDatePickerBuilder,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadQueue();
    }
  }

  void _selectLocation(String? location) {
    if (location == _selectedLocation) return;
    setState(() => _selectedLocation = location);
    _loadQueue();
  }

  void _toggleShowAllQueue() {
    setState(() => _showAllQueue = !_showAllQueue);
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    var initials = '';
    for (final part in parts) {
      if (part.isNotEmpty) initials += part[0].toUpperCase();
    }
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }

  /* This sends the next waiting patient in to the doctor in one tap,
  instead of opening that patient first. It asks for confirmation, then
  does exactly what "Send to Doctor" on the patient's own screen does:
  moves them to "Sent to Doctor" and notifies them that they are being
  called. */
  Future<void> _callNext() async {
    final next = _nextWaiting;
    if (next == null || _isCallingNext) return;

    final name = next['patient_name'] as String;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Call next patient?"),
        content: Text(
          "$name (${appointmentQueueLabel(next)} • ${next['location']}) will be sent "
          "to the doctor and notified that they are being called.",
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
            child: const Text("Call"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCallingNext = true);
    try {
      await QueueService.sendToDoctor(next['appointment_id'] as int);
      // The patient is already sent to the doctor at this point, so a
      // failed notification is reported on its own instead of looking
      // like the whole call failed.
      var notified = true;
      final patientUserId = next['user_id'] as int?;
      try {
        // A walk-in without an account has no app to notify; the staff
        // call their queue number out loud instead.
        if (patientUserId == null) throw StateError('walk-in');
        await NotificationService.create(
          userId: patientUserId,
          title: "You're Being Called",
          message:
              "Your appointment (${next['reference_no'] ?? ''}) is being sent "
              "to the doctor. Please stay nearby.",
          type: "Alerts",
          targetRoute: "/queue",
        );
      } catch (_) {
        notified = false;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notified
                ? "$name was called."
                : "$name was sent to the doctor, but the notification "
                      "couldn't be sent. Please call them in person.",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isCallingNext = false);
      _loadQueue(showSpinner: false);
    }
  }

  void _openPatientDetails(Map<String, dynamic> item) {
    final waitingList = waitingInLine(_queue, item)
        .map(
          (p) => {
            'initials': _getInitials(p['patient_name'] as String),
            'name': p['patient_name'] as String,
            'time': appointmentQueueLabel(p),
          },
        )
        .toList();

    Navigator.of(context)
        .push(
          smartCareRoute(
            transition: SmartCareTransition.subPage,
            builder: (context) => ServingScreen(
              appointmentId: item['appointment_id'] as int,
              patientUserId: item['user_id'] as int?,
              patientName: item['patient_name'] as String,
              referenceNo: item['reference_no'] as String? ?? '',
              queueLabel: appointmentQueueLabel(item),
              location: item['location'] as String,
              status: item['status'] as String,
              scheduleDate: item['schedule_date'] as String?,
              waitingPatients: waitingList,
            ),
          ),
        )
        .then((changed) {
          if (changed == true) _loadQueue();
        });
  }

  List<Widget> _buildQueueList() {
    final displayed = _showAllQueue ? _queue : _queue.take(4).toList();
    final children = <Widget>[];

    for (var i = 0; i < displayed.length; i++) {
      final item = displayed[i];
      children.add(
        _QueuePatientRow(
          name: item['patient_name'] as String,
          time: appointmentQueueLabel(item),
          location: _selectedLocation == null
              ? item['location'] as String
              : null,
          status: item['status'] as String,
          onTap: () => _openPatientDetails(item),
        ),
      );
      if (i < displayed.length - 1) {
        children.add(
          const Divider(height: 1, thickness: 1, color: Color(0xFFE3EFE1)),
        );
      }
    }

    return children;
  }

  Widget _buildLocationFilter() {
    final tablet = _isTablet(context);

    Widget chip(String label, String? location) {
      final selected = _selectedLocation == location;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        padding: tablet
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : null,
        labelPadding: tablet ? EdgeInsets.zero : null,
        onSelected: (_) => _selectLocation(location),
        showCheckmark: false,
        selectedColor: const Color(0xFF16751F),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? const Color(0xFF16751F) : const Color(0xFFD2E7D1),
        ),
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF16751F),
          fontSize: tablet ? 14 : 12,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip("All Clinics", null),
        for (final location in clinicLocations) chip(location, location),
      ],
    );
  }

  Widget _buildCallNextCard() {
    final needsClinic = _needsClinicForCallNext;
    final next = needsClinic ? null : _nextWaiting;
    final tablet = _isTablet(context);
    return Container(
      width: double.infinity,
      // On tablets the text and CALL NEXT button share one 60px-tall row.
      constraints: tablet ? const BoxConstraints(minHeight: 60) : null,
      padding: tablet
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 6)
          : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD2E7D1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFDDF6DD),
            child: Icon(Icons.campaign, color: Color(0xFF16751F), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Next in line",
                  style: TextStyle(color: Color(0xFF506D54), fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  needsClinic
                      ? "Pick a clinic above to call the next patient"
                      : next == null
                      ? "No patients waiting"
                      : next['patient_name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF1A3320),
                    fontSize: tablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (next != null)
                  Text(
                    "${appointmentQueueLabel(next)} • ${next['location']}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF506D54),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: tablet ? 44 : 38,
            child: ElevatedButton(
              onPressed: next == null || _isCallingNext ? null : _callNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16751F),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: tablet ? 24 : 16),
                textStyle: TextStyle(
                  fontSize: tablet ? 14 : 12,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isCallingNext
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("CALL NEXT"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _queue
        .where((p) => p['status'] == 'completed')
        .length;
    final pendingCount = _queue
        .where((p) => p['status'] != 'completed' && p['status'] != 'no_show')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F2E4),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.queue,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tablet = _isTablet(context);
            final horizontalPadding = tablet
                ? 24.0
                : constraints.maxWidth < 380
                ? 12.0
                : 16.0;

            return RefreshIndicator(
              color: const Color(0xFF16751F),
              onRefresh: _loadQueue,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SmartCareDashboardHeader(
                    title: "Queue Management",
                    subtitle: "Monitor queue and manage appointment flow",
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: tablet ? 1080 : double.infinity,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stats: fixed 110px-tall cards side by side on
                              // tablets, the original 2-column grid on phones.
                              if (tablet)
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 110,
                                        child: _StatCard(
                                          number: "$pendingCount",
                                          label: "Not Yet Done",
                                          icon: Icons.hourglass_top,
                                          large: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SizedBox(
                                        height: 110,
                                        child: _StatCard(
                                          number: "$completedCount",
                                          label: "Completed",
                                          icon: Icons.check_circle,
                                          large: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                GridView.count(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  childAspectRatio: 1.6,
                                  children: [
                                    _StatCard(
                                      number: "$pendingCount",
                                      label: "Not Yet Done",
                                      icon: Icons.hourglass_top,
                                    ),
                                    _StatCard(
                                      number: "$completedCount",
                                      label: "Completed",
                                      icon: Icons.check_circle,
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFD2E7D1),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _selectDate,
                                    child: Padding(
                                      padding: tablet
                                          ? const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 14,
                                            )
                                          : const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_month,
                                            color: Colors.green.shade700,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Select Date",
                                                  style: TextStyle(
                                                    color:
                                                        Colors.green.shade700,
                                                    fontSize: tablet ? 14 : 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                                  style: const TextStyle(
                                                    color: Color(0xFF1A3320),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.green.shade700,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildLocationFilter(),
                              // Calling a patient only makes sense for today's
                              // queue, not a past or future day.
                              if (_isToday && !_isLoading) ...[
                                const SizedBox(height: 16),
                                _buildCallNextCard(),
                              ],
                              const SizedBox(height: 24),
                              // Queue List Section
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Queue List",
                                    style: TextStyle(
                                      color: Color(0xFF1B6F2A),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _toggleShowAllQueue,
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF16751F),
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 32),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    child: Text(
                                      _showAllQueue
                                          ? "View Less >"
                                          : "View All >",
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_isLoading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF16751F),
                                    ),
                                  ),
                                )
                              else if (_queue.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: tablet
                                      ? const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 28,
                                        )
                                      : const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color(0xFFD5E4D5),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "No appointments for this date.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFF506D54),
                                      fontSize: tablet ? 15 : null,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color(0xFFD5E4D5),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
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
                                  child: Column(children: _buildQueueList()),
                                ),
                            ],
                          ),
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
    );
  }
}

class _QueuePatientRow extends StatelessWidget {
  const _QueuePatientRow({
    required this.name,
    required this.time,
    required this.location,
    required this.status,
    required this.onTap,
  });

  final String name;
  final String time;

  /// Shown next to the time only when the list mixes every clinic.
  final String? location;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _queueStatusColor(status);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: status == 'no_show'
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF16751F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                name.isEmpty ? "?" : name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A3320),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location == null ? time : "$time • $location",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF506D54),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _queueStatusLabel(status),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.number,
    required this.label,
    required this.icon,
    this.large = false,
  });

  final String number;
  final String label;
  final IconData icon;

  /// Tablet styling: bigger badge, number and label.
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: large
          ? const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
          : const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD2E7D1)),
        borderRadius: BorderRadius.circular(large ? 12 : 8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          if (large)
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF7EA),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF16751F), size: 36),
            )
          else
            CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFE0F4E1),
              child: Icon(icon, color: const Color(0xFF16751F), size: 18),
            ),
          SizedBox(width: large ? 16 : 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF16751F),
                    fontSize: large ? 36 : 20,
                    fontWeight: FontWeight.bold,
                    height: large ? 1.1 : null,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: large ? Colors.black87 : const Color(0xFF1A3320),
                    fontSize: large ? 16 : 11,
                    fontWeight: FontWeight.bold,
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
