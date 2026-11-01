import 'dart:async';

import 'package:flutter/material.dart';
import '../services/audit/audit_log_service.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';
import '../widgets/synced_horizontal_scroll.dart';
import '../widgets/smartcare_date_picker.dart';

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
    contentPadding: EdgeInsets.symmetric(
      horizontal: 8,
      vertical: large ? 10 : 8,
    ),
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
      builder: smartCareDatePickerBuilder,
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
      builder: smartCareDatePickerBuilder,
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
          style: TextStyle(
            color: const Color(0xFF1A3320),
            fontSize: _tablet ? 13 : 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  /// Tablets (wider than 800px) get larger filter and table text.
  bool get _tablet => MediaQuery.sizeOf(context).width > 800;

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
                style: TextStyle(fontSize: _tablet ? 14 : 12),
                decoration: _filterDecoration(
                  large: _tablet,
                  hintText: 'Enter a name',
                  prefixIcon: Icon(
                    Icons.search,
                    size: _tablet ? 18 : 16,
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
                    large: _tablet,
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      size: _tablet ? 18 : 14,
                      color: Color(0xFF6E8D73),
                    ),
                  ),
                  child: Text(
                    _startDate == null ? 'Any' : _formatDate(_startDate!),
                    style: TextStyle(fontSize: _tablet ? 14 : 12),
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
                decoration: _filterDecoration(large: _tablet),
                style: TextStyle(
                  fontSize: _tablet ? 14 : 12,
                  color: const Color(0xFF1A3320),
                ),
                hint: Text(
                  'All Types',
                  style: TextStyle(fontSize: _tablet ? 14 : 12),
                ),
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
                    large: _tablet,
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      size: _tablet ? 18 : 14,
                      color: Color(0xFF6E8D73),
                    ),
                  ),
                  child: Text(
                    _endDate == null ? 'Any' : _formatDate(_endDate!),
                    style: TextStyle(fontSize: _tablet ? 14 : 12),
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
                decoration: _filterDecoration(large: _tablet),
                style: TextStyle(
                  fontSize: _tablet ? 14 : 12,
                  color: const Color(0xFF1A3320),
                ),
                hint: Text(
                  'All Roles',
                  style: TextStyle(fontSize: _tablet ? 14 : 12),
                ),
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
            icon: Icon(Icons.clear, size: _tablet ? 18 : 15),
            label: Text(
              'Clear filters',
              style: TextStyle(fontSize: _tablet ? 14 : 12),
            ),
          ),
        ],
      ),
    );
  }

  // Fixed column widths keep the pinned header aligned with the rows.
  static const List<(String, double)> _columns = [
    ('User', 160),
    ('Action', 120),
    ('Resource Type', 130),
    ('Description', 320),
    ('Timestamp', 170),
  ];

  static const double _cellPadding = 10;

  /// Tablet columns are a bit wider to fit the larger text.
  double get _columnScale => _tablet ? 1.1 : 1.0;

  double get _tableWidth =>
      _columns.fold(0.0, (sum, column) => sum + column.$2) * _columnScale +
      _cellPadding * 2 * _columns.length;

  final HorizontalScrollGroup _tableScroll = HorizontalScrollGroup();

  Widget _cell(int column, Widget child) {
    return Container(
      width: _columns[column].$2 * _columnScale + _cellPadding * 2,
      padding: const EdgeInsets.symmetric(horizontal: _cellPadding),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  Widget _buildTableHeader() {
    final tablet = _tablet;
    return Container(
      decoration: BoxDecoration(
        color: tablet ? const Color(0xFFF8FCF7) : const Color(0xFFF6FBF5),
        border: const Border(bottom: BorderSide(color: Color(0xFFE3EFE1))),
      ),
      child: SyncedHorizontalScroll(
        group: _tableScroll,
        width: _tableWidth,
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        )
                      : const TextStyle(
                          color: Color(0xFF1A3320),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogRow(AuditLogEntry log, {required bool isLast}) {
    final actionColor = _actionColor(log.action);
    final tablet = _tablet;
    final cellStyle = tablet
        ? const TextStyle(color: Colors.black87, fontSize: 14.5)
        : const TextStyle(
            color: Color(0xFF1A3320),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
    final timestampStyle = tablet
        ? const TextStyle(color: Colors.black87, fontSize: 14)
        : cellStyle;

    final row = Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFE3EFE1))),
      ),
      child: SyncedHorizontalScroll(
        group: _tableScroll,
        width: _tableWidth,
        child: Row(
          children: [
            _cell(
              0,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    log.userName,
                    style: tablet
                        ? const TextStyle(
                            color: Colors.black87,
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                          )
                        : const TextStyle(
                            color: Color(0xFF1A3320),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                  ),
                  Text(
                    log.role,
                    style: tablet
                        ? TextStyle(color: Colors.grey.shade600, fontSize: 13.5)
                        : const TextStyle(
                            color: Color(0xFF6E8D73),
                            fontSize: 10,
                          ),
                  ),
                ],
              ),
            ),
            _cell(
              1,
              Container(
                padding: tablet
                    ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
                    : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(tablet ? 20 : 6),
                ),
                child: Text(
                  log.action,
                  style: TextStyle(
                    color: actionColor,
                    fontSize: tablet ? 13 : 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _cell(2, Text(log.resourceType, style: cellStyle)),
            _cell(
              3,
              InkWell(
                onTap: () => _showFullDescription(log),
                child: Text(
                  log.description,
                  style: cellStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ),
            _cell(4, Text(log.createdAt, style: timestampStyle)),
          ],
        ),
      ),
    );

    if (!isLast) return row;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      child: row,
    );
  }

  List<Widget> _buildTableSlivers() {
    if (_isLoading) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF8B2F2F)),
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
          ),
        ),
      ];
    }
    if (_logs.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No logs found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      // The card border is painted on top so the pinned header and rows keep
      // the rounded outline; the group keeps the header pinned only while the
      // table is on screen.
      DecoratedSliver(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3EFE1), width: 1),
        ),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _AuditTableHeaderDelegate(
                height: _tablet ? 48 : 50,
                background: _tablet
                    ? const Color(0xFFF8FCF7)
                    : const Color(0xFFF6FBF5),
                child: _buildTableHeader(),
              ),
            ),
            SliverList.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) =>
                  _buildLogRow(_logs[index], isLast: index == _logs.length - 1),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF5),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.profile,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SmartCareDashboardHeader(
                title: "Audit Logs",
                subtitle: "View system activity and audit trail.",
              ),
            ),
            SliverLayoutBuilder(
              builder: (context, constraints) {
                // Tablets: centered at up to 1080 with at least 24px sides.
                // Phones: up to 1400 with 16px sides, like before.
                final tablet = _tablet;
                final maxWidth = tablet ? 1080.0 : 1400.0;
                final minSide = tablet ? 24.0 : 16.0;
                final extra = (constraints.crossAxisExtent - maxWidth) / 2;
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
                            _buildFilterActions(),
                          ],
                        ),
                      ),
                      ..._buildTableSlivers(),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _AuditTableHeaderDelegate({
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
    // Solid background so rows never show through.
    return Container(
      color: background,
      child: SizedBox.expand(child: child),
    );
  }

  @override
  bool shouldRebuild(_AuditTableHeaderDelegate oldDelegate) =>
      oldDelegate.child != child ||
      oldDelegate.height != height ||
      oldDelegate.background != background;
}
