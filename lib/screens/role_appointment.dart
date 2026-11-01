import 'package:flutter/material.dart';

import '../data/location_schedule.dart';
import '../services/appointment/appointment_service.dart';
import '../services/notifications/notification_service.dart';
import '../state/app_session.dart';
import '../widgets/cancel_reason_dialog.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';
<<<<<<< HEAD
import '../widgets/synced_horizontal_scroll.dart';
import '../widgets/walk_in_dialog.dart';
import '../widgets/smartcare_date_picker.dart';
=======
import '../widgets/walk_in_dialog.dart';
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a

const List<String> _filterableStatuses = [
  'booked',
  'completed',
  'cancelled',
  'no_show',
];

String _formatFilterDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

<<<<<<< HEAD
InputDecoration _filterDecoration({
  String? hintText,
  Widget? prefixIcon,
  bool large = false,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      color: const Color(0xFFBBBBBB),
      fontSize: large ? 13.5 : 11.5,
    ),
=======
InputDecoration _filterDecoration({String? hintText, Widget? prefixIcon}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11.5),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
    prefixIcon: prefixIcon,
    prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 20),
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF006837), width: 1.5),
    ),
    filled: true,
    fillColor: const Color(0xFFFAFAFA),
<<<<<<< HEAD
    contentPadding: EdgeInsets.symmetric(
      horizontal: 8,
      vertical: large ? 10 : 8,
    ),
=======
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
  );
}

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

/// Shows "—" for a contact number or email that was never filled in.
String _orDash(Object? value) {
  final text = (value as String? ?? '').trim();
  return text.isEmpty ? '—' : text;
}

String _formatDate(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  if (date == null) return isoDate;
  return "${_monthNames[date.month - 1]} ${date.day}, ${date.year}";
}

String _formatCreatedAt(String createdAt) {
  final dt = DateTime.tryParse(createdAt);
  if (dt == null) return createdAt;
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return "${_monthNames[dt.month - 1]} ${dt.day}, ${dt.year} $hour12:$minute $ampm";
}

Color _statusColor(String status) {
  switch (status) {
    case 'booked':
      return const Color(0xFFB3D9E8);
    case 'sent_to_doctor':
      return const Color(0xFFF3E8FF);
    case 'serving':
      return const Color(0xFFD9F0D0);
    case 'completed':
      return const Color(0xFFC8E6C9);
    case 'cancelled':
      return const Color(0xFFE8B4B8);
    case 'no_show':
      return const Color(0xFFD1D5DB);
    default:
      return const Color(0xFFE0E0E0);
  }
}

/// Cancelled and completed appointments are final: their status can no
/// longer be changed (the backend refuses it too).
bool _isFinalStatus(String status) =>
    status == 'cancelled' || status == 'completed';

String _statusLabel(String status) {
  switch (status) {
    case 'sent_to_doctor':
      return 'SENT TO DOCTOR';
    case 'no_show':
      return 'NO-SHOW';
    default:
      return status.toUpperCase();
  }
}

class RoleAppointmentScreen extends StatefulWidget {
  const RoleAppointmentScreen({super.key});

  @override
  State<RoleAppointmentScreen> createState() => _RoleAppointmentScreenState();
}

class _RoleAppointmentScreenState extends State<RoleAppointmentScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedStatus;
  String? _selectedLocation;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _updatingAppointmentId;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final appointments = await AppointmentService.getAllAppointments();
      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _changeStatus(
    Map<String, dynamic> appointment,
    String status,
  ) async {
    final appointmentId = appointment['appointment_id'] as int;
    if (appointment['status'] == status ||
        _isFinalStatus(appointment['status'] as String)) {
      return;
    }
    if (status == 'cancelled') {
      await _cancelAppointment(appointment);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Status?'),
        content: Text(
          'Change this appointment\'s status from '
          '${_statusLabel(appointment['status'] as String)} to '
          '${_statusLabel(status)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006837),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _updatingAppointmentId = appointmentId);
    try {
      await AppointmentService.updateStatus(
        appointmentId: appointmentId,
        status: status,
        actorUserId: SmartCareSession.currentUserId,
      );
      if (!mounted) return;
      setState(() {
        appointment['status'] = status;
        _updatingAppointmentId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingAppointmentId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  /* Cancelling asks for a reason first, the same way as on the Now
  Serving screen. The reason is saved in the audit log and sent to the
  patient in a notification (walk-ins without an account are skipped).
  If only the notification fails, the cancel still stands. */
  Future<void> _cancelAppointment(Map<String, dynamic> appointment) async {
    final appointmentId = appointment['appointment_id'] as int;
    final reason = await showCancelReasonDialog(
      context,
      patientName: appointment['full_name'] as String,
    );
    if (reason == null || !mounted) return;

    setState(() => _updatingAppointmentId = appointmentId);
    try {
      await AppointmentService.cancel(
        appointmentId,
        actorUserId: SmartCareSession.currentUserId,
        reason: reason,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingAppointmentId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    }

    var notified = true;
    final patientUserId = appointment['user_id'] as int?;
    if (patientUserId != null) {
      try {
        await NotificationService.create(
          userId: patientUserId,
          title: "Appointment Cancelled",
          message:
              "Your appointment (${appointment['reference_no'] ?? ''}) was "
              "cancelled by the clinic. Reason: $reason",
          type: "Alerts",
          targetRoute: "/appointment",
        );
      } catch (_) {
        notified = false;
      }
    }

    if (!mounted) return;
    setState(() {
      appointment['status'] = 'cancelled';
      _updatingAppointmentId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notified
              ? "Appointment cancelled."
              : "Appointment cancelled, but the patient couldn't be notified.",
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    final query = _searchController.text.trim().toLowerCase();
    return _appointments.where((a) {
      if (_selectedStatus != null && a['status'] != _selectedStatus) {
        return false;
      }
      if (_selectedLocation != null && a['location'] != _selectedLocation) {
        return false;
      }
      final scheduleDate = DateTime.tryParse(a['schedule_date'] as String);
      if (_startDate != null &&
          scheduleDate != null &&
          scheduleDate.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null &&
          scheduleDate != null &&
          scheduleDate.isAfter(_endDate!)) {
        return false;
      }
      if (query.isNotEmpty) {
        final name = (a['full_name'] as String).toLowerCase();
        final ref = (a['reference_no'] as String? ?? '').toLowerCase();
        final contact = (a['contact_number'] as String? ?? '').toLowerCase();
        final email = (a['email'] as String? ?? '').toLowerCase();
        if (!name.contains(query) &&
            !ref.contains(query) &&
            !contact.contains(query) &&
            !email.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
<<<<<<< HEAD
      builder: smartCareDatePickerBuilder,
=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
<<<<<<< HEAD
      builder: smartCareDatePickerBuilder,
=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _endDate = picked);
  }

<<<<<<< HEAD
  /// Tablets (wider than 800px) get larger filter and table text.
  bool get _tablet => MediaQuery.sizeOf(context).width > 800;

=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
  Widget _filterField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
<<<<<<< HEAD
          style: TextStyle(
            color: const Color(0xFF1A3320),
            fontSize: _tablet ? 13 : 10.5,
=======
          style: const TextStyle(
            color: Color(0xFF1A3320),
            fontSize: 10.5,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _filterRow(Widget left, Widget right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 8),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3EFE1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterRow(
            _filterField(
              label: 'Search Patient',
              child: TextField(
                controller: _searchController,
<<<<<<< HEAD
                style: TextStyle(fontSize: _tablet ? 14 : 12),
                decoration: _filterDecoration(
                  large: _tablet,
                  hintText: 'Name, Reference #, Contact, or Email',
                  prefixIcon: Icon(
                    Icons.search,
                    size: _tablet ? 18 : 16,
=======
                style: const TextStyle(fontSize: 12),
                decoration: _filterDecoration(
                  hintText: 'Name, Reference #, Contact, or Email',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 16,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                    color: Color(0xFF6E8D73),
                  ),
                ),
              ),
            ),
            _filterField(
              label: 'Start Date',
              child: InkWell(
                onTap: _pickStartDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: _filterDecoration(
<<<<<<< HEAD
                    large: _tablet,
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      size: _tablet ? 18 : 14,
=======
                    prefixIcon: const Icon(
                      Icons.calendar_today,
                      size: 14,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                      color: Color(0xFF6E8D73),
                    ),
                  ),
                  child: Text(
                    _startDate == null ? 'Any' : _formatFilterDate(_startDate!),
<<<<<<< HEAD
                    style: TextStyle(fontSize: _tablet ? 14 : 12),
=======
                    style: const TextStyle(fontSize: 12),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                  ),
                ),
              ),
            ),
          ),
          _filterRow(
            _filterField(
              label: 'Clinic',
              child: DropdownButtonFormField<String>(
                initialValue: _selectedLocation,
<<<<<<< HEAD
                decoration: _filterDecoration(large: _tablet),
                style: TextStyle(
                  fontSize: _tablet ? 14 : 12,
                  color: const Color(0xFF1A3320),
                ),
                hint: Text(
                  'All Clinic',
                  style: TextStyle(fontSize: _tablet ? 14 : 12),
                ),
=======
                decoration: _filterDecoration(),
                style: const TextStyle(fontSize: 12, color: Color(0xFF1A3320)),
                hint: const Text('All Clinic', style: TextStyle(fontSize: 12)),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Clinic'),
                  ),
                  ...clinicLocations.map(
                    (location) => DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedLocation = value),
              ),
            ),
            _filterField(
              label: 'End Date',
              child: InkWell(
                onTap: _pickEndDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: _filterDecoration(
<<<<<<< HEAD
                    large: _tablet,
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      size: _tablet ? 18 : 14,
=======
                    prefixIcon: const Icon(
                      Icons.calendar_today,
                      size: 14,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                      color: Color(0xFF6E8D73),
                    ),
                  ),
                  child: Text(
                    _endDate == null ? 'Any' : _formatFilterDate(_endDate!),
<<<<<<< HEAD
                    style: TextStyle(fontSize: _tablet ? 14 : 12),
=======
                    style: const TextStyle(fontSize: 12),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                  ),
                ),
              ),
            ),
          ),
          _filterRow(
            _filterField(
              label: 'Status',
              child: DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
<<<<<<< HEAD
                decoration: _filterDecoration(large: _tablet),
                style: TextStyle(
                  fontSize: _tablet ? 14 : 12,
                  color: const Color(0xFF1A3320),
                ),
                hint: Text(
                  'All Status',
                  style: TextStyle(fontSize: _tablet ? 14 : 12),
                ),
=======
                decoration: _filterDecoration(),
                style: const TextStyle(fontSize: 12, color: Color(0xFF1A3320)),
                hint: const Text('All Status', style: TextStyle(fontSize: 12)),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Status'),
                  ),
                  ..._filterableStatuses.map(
                    (status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text(_statusLabel(status)),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value),
              ),
            ),
            _filterField(
              label: 'Refresh',
              child: InkWell(
                onTap: _load,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: _filterDecoration(
<<<<<<< HEAD
                    large: _tablet,
                    prefixIcon: Icon(
                      Icons.refresh,
                      size: _tablet ? 18 : 16,
                      color: Color(0xFF006837),
                    ),
                  ),
                  child: Text(
                    'Refresh',
                    style: TextStyle(
                      fontSize: _tablet ? 14 : 12,
=======
                    prefixIcon: const Icon(
                      Icons.refresh,
                      size: 16,
                      color: Color(0xFF006837),
                    ),
                  ),
                  child: const Text(
                    'Refresh',
                    style: TextStyle(
                      fontSize: 12,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                      color: Color(0xFF006837),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Records a walk-in patient, then reloads the list so it shows up.
  Future<void> _addWalkIn() async {
    final booking = await showWalkInDialog(context);
    if (booking == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Walk-in recorded. Queue number ${booking.queueCode} "
          "(${booking.code}).",
        ),
      ),
    );
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  // Fixed column widths keep the pinned header aligned with the rows.
  static const List<(String, double)> _columns = [
    ('APPOINTMENT ID', 130),
    ('REFERENCE NO.', 150),
    ('QUEUE NO.', 110),
    ('FULL NAME', 180),
    ('CONTACT NO.', 130),
    ('EMAIL', 220),
    ('LOCATION', 100),
    ('SCHEDULE DATE & SESSION', 215),
    ('STATUS', 170),
    ('CREATED AT', 190),
  ];

  final HorizontalScrollGroup _tableScroll = HorizontalScrollGroup();

  double _cellPadding(bool tablet) => tablet ? 8 : 12;

  double _tableWidth(bool tablet) =>
      _columns.fold(0.0, (sum, column) => sum + column.$2) *
          _columnScale(tablet) +
      _cellPadding(tablet) * 2 * _columns.length;

  /// Tablet columns are a bit wider to fit the larger text.
  double _columnScale(bool tablet) => tablet ? 1.1 : 1.0;

  Widget _cell(int column, Widget child, bool tablet) {
    final padding = _cellPadding(tablet);
    return Container(
      width: _columns[column].$2 * _columnScale(tablet) + padding * 2,
      padding: EdgeInsets.symmetric(horizontal: padding),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  Widget _buildTableHeader(bool tablet) {
    return Container(
      decoration: BoxDecoration(
        color: tablet ? const Color(0xFFF8FCF7) : const Color(0xFFF6FBF5),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SyncedHorizontalScroll(
        group: _tableScroll,
        width: _tableWidth(tablet),
        child: Row(
          children: [
            for (var i = 0; i < _columns.length; i++)
              _cell(
                i,
                Text(
                  _columns[i].$1,
                  style: tablet
                      ? const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        )
                      : const TextStyle(
                          color: Color(0xFF1A3320),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                ),
                tablet,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCell(Map<String, dynamic> appointment, bool tablet) {
    final status = appointment['status'] as String;
    if (_updatingAppointmentId == appointment['appointment_id']) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF006837),
        ),
      );
    }
    return PopupMenuButton<String>(
      enabled: !_isFinalStatus(status),
      tooltip: _isFinalStatus(status)
          ? 'This appointment is final and can no longer be changed'
          : 'Change status',
      onSelected: (value) => _changeStatus(appointment, value),
      itemBuilder: (context) => _filterableStatuses
          .map(
            (option) =>
                PopupMenuItem(value: option, child: Text(_statusLabel(option))),
          )
          .toList(),
      child: Container(
        padding: tablet
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor(status),
          borderRadius: BorderRadius.circular(tablet ? 6 : 4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _statusLabel(status),
              style: TextStyle(
                color: const Color(0xFF1A3320),
                fontSize: tablet ? 13 : 11,
                fontWeight: tablet ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              _isFinalStatus(status) ? Icons.lock : Icons.arrow_drop_down,
              size: _isFinalStatus(status) ? 12 : 16,
              color: const Color(0xFF1A3320),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentRow(
    Map<String, dynamic> appointment, {
    required bool isLast,
    required bool tablet,
  }) {
    // Phones keep the original 12px text; tablets scale each column.
    TextStyle style(double tabletSize, {FontWeight? weight}) => tablet
        ? TextStyle(
            color: Colors.black87,
            fontSize: tabletSize,
            fontWeight: weight,
          )
        : const TextStyle(fontSize: 12);
    final idStyle = style(14.5);
    final nameStyle = style(15, weight: FontWeight.w600);
    final infoStyle = style(14.5);
    final scheduleStyle = style(14);

    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SyncedHorizontalScroll(
        group: _tableScroll,
        width: _tableWidth(tablet),
        child: Row(
          children: [
            _cell(
              0,
              Text("${appointment['appointment_id']}", style: idStyle),
              tablet,
            ),
            _cell(
              1,
              Text(
                appointment['reference_no'] as String? ?? '',
                style: idStyle,
              ),
              tablet,
            ),
            _cell(
              2,
              Text(
                "${appointmentQueueLabel(appointment)}\n"
                "${bookingTypeLabel(appointment)}",
                style: infoStyle,
              ),
              tablet,
            ),
            _cell(
              3,
              Text(appointment['full_name'] as String, style: nameStyle),
              tablet,
            ),
            _cell(
              4,
              Text(_orDash(appointment['contact_number']), style: infoStyle),
              tablet,
            ),
            _cell(
              5,
              Text(
                _orDash(appointment['email']),
                style: nameStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              tablet,
            ),
            _cell(
              6,
              Text(appointment['location'] as String, style: infoStyle),
              tablet,
            ),
            _cell(
              7,
              Text(
                "${_formatDate(appointment['schedule_date'] as String)}\n"
                "${appointmentTimeLabel(appointment)}",
                style: scheduleStyle,
              ),
              tablet,
            ),
            _cell(8, _buildStatusCell(appointment, tablet), tablet),
            _cell(
              9,
              Text(
                _formatCreatedAt(appointment['created_at'] as String),
                style: scheduleStyle,
              ),
              tablet,
            ),
          ],
        ),
      ),
    );

    if (!isLast) return row;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      child: row,
    );
  }

  List<Widget> _buildTableSlivers(bool tablet) {
    if (_isLoading) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF006837)),
            ),
          ),
        ),
      ];
    }
    if (_error != null) {
      return [
        SliverToBoxAdapter(
          child: Column(
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      ];
    }
    final appointments = _filteredAppointments;
    if (appointments.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                "No appointments found.",
                style: TextStyle(color: Color(0xFF6E8D73)),
              ),
            ),
          ),
        ),
      ];
    }

    return [
      // The card outline is painted on top so the pinned header and rows
      // keep the rounded border; the group keeps the header pinned only
      // while the table is on screen.
      DecoratedSliver(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE3EFE1), width: 1),
        ),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _AppointmentTableHeaderDelegate(
                // Phones keep the original 48px header and colour.
                height: tablet ? 52 : 48,
                background: tablet
                    ? const Color(0xFFF8FCF7)
                    : const Color(0xFFF6FBF5),
                child: _buildTableHeader(tablet),
              ),
            ),
            SliverList.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) => _buildAppointmentRow(
                appointments[index],
                isLast: index == appointments.length - 1,
                tablet: tablet,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Tablets (wider than 800px) get a 1100px container and larger table
    // text; phones keep the original sizes.
    final tablet = MediaQuery.sizeOf(context).width > 800;
    final maxContentWidth = tablet ? 1100.0 : 1400.0;
    final minSide = tablet ? 24.0 : 16.0;

=======
  @override
  Widget build(BuildContext context) {
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF5),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.profile,
      ),
      body: SafeArea(
<<<<<<< HEAD
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SmartCareDashboardHeader(
                title: "Appointments",
                subtitle: "Manage and review appointments.",
              ),
            ),
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final extra =
                    (constraints.crossAxisExtent - maxContentWidth) / 2;
                final side = extra > minSide ? extra : minSide;
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 20, side, 26),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFilterPanel(),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Record List',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A3320),
                                    ),
                                  ),
                                ),
                                if (SmartCareSession.currentRole ==
                                    UserRole.secretary)
                                  ElevatedButton.icon(
                                    onPressed: _addWalkIn,
                                    icon: const Icon(
                                      Icons.person_add,
                                      size: 18,
                                    ),
                                    label: const Text('Add Walk-in'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF006837),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      ..._buildTableSlivers(tablet),
                    ],
                  ),
                );
              },
            ),
          ],
=======
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SmartCareDashboardHeader(
                title: "Appointments",
                subtitle: "Manage and review appointments.",
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 26),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFilterPanel(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Record List',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A3320),
                                ),
                              ),
                            ),
                            if (SmartCareSession.currentRole ==
                                UserRole.secretary)
                              ElevatedButton.icon(
                                onPressed: _addWalkIn,
                                icon: const Icon(Icons.person_add, size: 18),
                                label: const Text('Add Walk-in'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006837),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF006837),
                              ),
                            ),
                          )
                        else if (_error != null)
                          Column(
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                              TextButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          )
                        else if (_filteredAppointments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                "No appointments found.",
                                style: TextStyle(color: Color(0xFF6E8D73)),
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE3EFE1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0x0A000000),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateColor.resolveWith(
                                  (states) => const Color(0xFFF6FBF5),
                                ),
                                headingRowHeight: 48,
                                dataRowMinHeight: 56,
                                dataRowMaxHeight: 72,
                                columnSpacing: 24,
                                headingTextStyle: const TextStyle(
                                  color: Color(0xFF1A3320),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                columns: const [
                                  DataColumn(label: Text('APPOINTMENT ID')),
                                  DataColumn(label: Text('REFERENCE NO.')),
                                  DataColumn(label: Text('QUEUE NO.')),
                                  DataColumn(label: Text('FULL NAME')),
                                  DataColumn(label: Text('CONTACT NO.')),
                                  DataColumn(label: Text('EMAIL')),
                                  DataColumn(label: Text('LOCATION')),
                                  DataColumn(
                                    label: Text('SCHEDULE DATE & SESSION'),
                                  ),
                                  DataColumn(label: Text('STATUS')),
                                  DataColumn(label: Text('CREATED AT')),
                                ],
                                rows: _filteredAppointments.map((appointment) {
                                  final status =
                                      appointment['status'] as String;
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          "${appointment['appointment_id']}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          appointment['reference_no']
                                                  as String? ??
                                              '',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          "${appointmentQueueLabel(appointment)}\n"
                                          "${bookingTypeLabel(appointment)}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          appointment['full_name'] as String,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _orDash(appointment['contact_number']),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _orDash(appointment['email']),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          appointment['location'] as String,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          "${_formatDate(appointment['schedule_date'] as String)}\n"
                                          "${appointmentTimeLabel(appointment)}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        _updatingAppointmentId ==
                                                appointment['appointment_id']
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFF006837),
                                                    ),
                                              )
                                            : PopupMenuButton<String>(
                                                enabled: !_isFinalStatus(
                                                  status,
                                                ),
                                                tooltip: _isFinalStatus(status)
                                                    ? 'This appointment is final and can no longer be changed'
                                                    : 'Change status',
                                                onSelected: (value) =>
                                                    _changeStatus(
                                                      appointment,
                                                      value,
                                                    ),
                                                itemBuilder: (context) =>
                                                    _filterableStatuses
                                                        .map(
                                                          (option) =>
                                                              PopupMenuItem(
                                                                value: option,
                                                                child: Text(
                                                                  _statusLabel(
                                                                    option,
                                                                  ),
                                                                ),
                                                              ),
                                                        )
                                                        .toList(),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _statusColor(status),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        _statusLabel(status),
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xFF1A3320,
                                                          ),
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Icon(
                                                        _isFinalStatus(status)
                                                            ? Icons.lock
                                                            : Icons
                                                                  .arrow_drop_down,
                                                        size:
                                                            _isFinalStatus(
                                                              status,
                                                            )
                                                            ? 12
                                                            : 16,
                                                        color: Color(
                                                          0xFF1A3320,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                      ),
                                      DataCell(
                                        Text(
                                          _formatCreatedAt(
                                            appointment['created_at'] as String,
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
        ),
      ),
    );
  }
}
<<<<<<< HEAD

class _AppointmentTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _AppointmentTableHeaderDelegate({
    required this.height,
    required this.background,
    required this.child,
  });

  final double height;
  final Color background;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Solid background so scrolled rows never show through.
    return Container(
      color: background,
      child: SizedBox.expand(child: child),
    );
  }

  @override
  bool shouldRebuild(_AppointmentTableHeaderDelegate oldDelegate) =>
      oldDelegate.child != child ||
      oldDelegate.height != height ||
      oldDelegate.background != background;
}
=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
