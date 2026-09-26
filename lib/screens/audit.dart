import 'dart:async';

import 'package:flutter/material.dart';
import '../services/audit/audit_log_service.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';

Color _actionColor(String action) {
  switch (action) {
    case 'CREATE':
    case 'REGISTER':
      return const Color(0xFF146F1B);
    case 'UPDATE':
      return const Color(0xFF7C3AED);
    case 'DELETE':
      return const Color(0xFFC41E3A);
    case 'LOGIN':
      return const Color(0xFF1F5AA2);
    default:
      return const Color(0xFF6E8D73);
  }
}

String _formatDate(DateTime date) {
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

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final TextEditingController _nameFilterController = TextEditingController();
  List<AuditLogEntry> _logs = [];
  bool _isLoading = true;
  String? _error;

  String? _selectedResourceType;
  String? _selectedRole;
  DateTime? _startDate;
  DateTime? _endDate;

  Timer? _nameFilterDebounce;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _nameFilterController.addListener(_onNameFilterChanged);
  }

  void _onNameFilterChanged() {
    _nameFilterDebounce?.cancel();
    _nameFilterDebounce = Timer(const Duration(milliseconds: 400), _loadLogs);
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final logs = await AuditLogService.getLogs(
        resourceType: _selectedResourceType,
        role: _selectedRole,
        search: _nameFilterController.text.trim().isEmpty
            ? null
            : _nameFilterController.text.trim(),
        startDate: _startDate == null ? null : _formatDate(_startDate!),
        endDate: _endDate == null ? null : _formatDate(_endDate!),
      );
      if (!mounted) return;
      setState(() {
        _logs = logs;
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

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _startDate = picked);
    _loadLogs();
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _endDate = picked);
    _loadLogs();
  }

  @override
  void dispose() {
    _nameFilterDebounce?.cancel();
    _nameFilterController.dispose();
    super.dispose();
  }

  void _showFullDescription(AuditLogEntry log) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${log.action} · ${log.resourceType}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(log.description),
              const SizedBox(height: 12),
              Text(
                '${log.userName} (${log.role}) · ${log.createdAt}',
                style: const TextStyle(color: Color(0xFF6E8D73), fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
      margin: const EdgeInsets.only(bottom: 16),
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
              label: 'Filter by name',
              child: TextField(
                controller: _nameFilterController,
                style: const TextStyle(fontSize: 12),
                decoration: _filterDecoration(
                  hintText: 'Enter a name',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 16,
                    color: Color(0xFF6E8D73),
                  ),
                ),
              ),
            ),
            _filterField(
              label: 'Start date',
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
                    _startDate == null ? 'Any' : _formatDate(_startDate!),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
          _filterRow(
            _filterField(
              label: 'Resource Type',
              child: DropdownButtonFormField<String>(
                initialValue: _selectedResourceType,
                decoration: _filterDecoration(),
                style: const TextStyle(fontSize: 12, color: Color(0xFF1A3320)),
                hint: const Text('All Types', style: TextStyle(fontSize: 12)),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Types'),
                  ),
                  ...auditResourceTypes.map(
                    (type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedResourceType = value);
                  _loadLogs();
                },
              ),
            ),
            _filterField(
              label: 'End date',
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
                    _endDate == null ? 'Any' : _formatDate(_endDate!),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
          _filterRow(
            _filterField(
              label: 'Performed By',
              child: DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: _filterDecoration(),
                style: const TextStyle(fontSize: 12, color: Color(0xFF1A3320)),
                hint: const Text('All Roles', style: TextStyle(fontSize: 12)),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Roles'),
                  ),
                  ...auditRoles.map(
                    (role) => DropdownMenuItem<String>(
                      value: role,
                      child: Text(role[0].toUpperCase() + role.substring(1)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedRole = value);
                  _loadLogs();
                },
              ),
            ),
            _filterField(
              label: 'Refresh',
              child: InkWell(
                onTap: _loadLogs,
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

  Widget _buildFilterActions() {
    final hasActiveFilters =
        _selectedResourceType != null ||
        _selectedRole != null ||
        _nameFilterController.text.isNotEmpty ||
        _startDate != null ||
        _endDate != null;

    if (!hasActiveFilters) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedResourceType = null;
                _selectedRole = null;
                _startDate = null;
                _endDate = null;
                _nameFilterController.clear();
              });
              _loadLogs();
            },
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(Icons.clear, size: 15),
            label: const Text('Clear filters', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
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
                title: "Audit Logs",
                subtitle: "View system activity and audit trail.",
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
                        _buildFilterActions(),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF006837),
                              ),
                            ),
                          )
                        else if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF8B2F2F),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadLogs,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF006837),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        else
                          // Audit Logs Table
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
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
                              child: IntrinsicWidth(
                                child: Column(
                                  children: [
                                    DataTable(
                                      headingRowColor:
                                          WidgetStateColor.resolveWith(
                                            (states) => const Color(0xFFF6FBF5),
                                          ),
                                      headingRowHeight: 56,
                                      dataRowMinHeight: 64,
                                      dataRowMaxHeight: 76,
                                      columnSpacing: 20,
                                      headingTextStyle: const TextStyle(
                                        color: Color(0xFF1A3320),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('User')),
                                        DataColumn(label: Text('Action')),
                                        DataColumn(
                                          label: Text('Resource Type'),
                                        ),
                                        DataColumn(label: Text('Description')),
                                        DataColumn(label: Text('Timestamp')),
                                      ],
                                      rows: _logs.map((log) {
                                        final actionColor = _actionColor(
                                          log.action,
                                        );
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    log.userName,
                                                    style: const TextStyle(
                                                      color: Color(0xFF1A3320),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    log.role,
                                                    style: const TextStyle(
                                                      color: Color(0xFF6E8D73),
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: actionColor.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  log.action,
                                                  style: TextStyle(
                                                    color: actionColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                log.resourceType,
                                                style: const TextStyle(
                                                  color: Color(0xFF1A3320),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              InkWell(
                                                onTap: () =>
                                                    _showFullDescription(log),
                                                child: Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxWidth: 320,
                                                      ),
                                                  child: Text(
                                                    log.description,
                                                    style: const TextStyle(
                                                      color: Color(0xFF1A3320),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                log.createdAt,
                                                style: const TextStyle(
                                                  color: Color(0xFF1A3320),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Center(
                                        child: Container(
                                          width: 40,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD0D7D0),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (!_isLoading && _error == null && _logs.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 48,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No logs found',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
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
