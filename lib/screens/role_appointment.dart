import 'package:flutter/material.dart';

import '../data/location_schedule.dart';
import '../services/appointment/appointment_service.dart';
import '../state/app_session.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';

const List<String> _filterableStatuses = ['booked', 'completed', 'cancelled'];

String _formatFilterDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

InputDecoration _filterDecoration({String? hintText, Widget? prefixIcon}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11.5),
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
    default:
      return const Color(0xFFE0E0E0);
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'sent_to_doctor':
      return 'SENT TO DOCTOR';
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
    if (appointment['status'] == status) return;

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
        if (!name.contains(query) && !ref.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
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
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _endDate = picked);
  }

  Widget _filterField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF1A3320),
            fontSize: 10.5,
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
                style: const TextStyle(fontSize: 12),
                decoration: _filterDecoration(
                  hintText: 'Name or Reference #',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 16,
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
                    prefixIcon: const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Color(0xFF6E8D73),
                    ),
                  ),
                  child: Text(
                    _startDate == null ? 'Any' : _formatFilterDate(_startDate!),
                    style: const TextStyle(fontSize: 12),
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
                decoration: _filterDecoration(),
                style: const TextStyle(fontSize: 12, color: Color(0xFF1A3320)),
                hint: const Text('All Clinic', style: TextStyle(fontSize: 12)),
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
                    prefixIcon: const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Color(0xFF6E8D73),
                    ),
                  ),
                  child: Text(
                    _endDate == null ? 'Any' : _formatFilterDate(_endDate!),
                    style: const TextStyle(fontSize: 12),
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
                decoration: _filterDecoration(),
                style: const TextStyle(fontSize: 12, color: Color(0xFF1A3320)),
                hint: const Text('All Status', style: TextStyle(fontSize: 12)),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF5),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.profile,
      ),
      body: SafeArea(
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
                        const Text(
                          'Record List',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3320),
                          ),
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
                                  DataColumn(label: Text('FULL NAME')),
                                  DataColumn(label: Text('LOCATION')),
                                  DataColumn(
                                    label: Text('SCHEDULE DATE & TIME'),
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
                                          appointment['full_name'] as String,
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
                                          "${appointment['time_slot']}",
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
                                                tooltip: 'Change status',
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
                                                      const Icon(
                                                        Icons.arrow_drop_down,
                                                        size: 16,
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
        ),
      ),
    );
  }
}
