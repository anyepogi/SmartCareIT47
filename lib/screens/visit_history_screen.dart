import 'package:flutter/material.dart';

import '../services/appointment/appointment_service.dart';
import '../state/app_session.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';

const List<String> _monthNames = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
];

String _formatVisitDate(String isoDate, String timeSlot) {
  final date = DateTime.tryParse(isoDate);
  if (date == null) return "$isoDate - $timeSlot";
  return "${_monthNames[date.month - 1]} ${date.day}, ${date.year} - $timeSlot";
}

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return "P";
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

class VisitHistoryScreen extends StatelessWidget {
  const VisitHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = SmartCareSession.currentRole;
    final isStaff = role.canSwitchStaffRole;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F2E4),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.visits,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _DashboardDetailHeader(
                title: isStaff ? 'Patient Visit History' : 'Visit History',
                subtitle: isStaff
                    ? 'See which patients visited the clinic and where they were served.'
                    : 'Review your clinic visits and completed checkups.',
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: isStaff
                    ? const _StaffVisitHistory()
                    : const _PatientVisitHistory(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const List<String> _clinicBranches = ['Sta. Rita', 'Guagua', 'Lubao'];

class _StaffVisitHistory extends StatefulWidget {
  const _StaffVisitHistory();

  @override
  State<_StaffVisitHistory> createState() => _StaffVisitHistoryState();
}

class _StaffVisitHistoryState extends State<_StaffVisitHistory> {
  List<Map<String, dynamic>> _visits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final visits = await AppointmentService.getVisitHistory();
      if (!mounted) return;
      setState(() {
        _visits = visits;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F6B2F)),
        ),
      );
    }

    final clinicCount = _visits
        .map((v) => v['location'] as String)
        .toSet()
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryCard(
          icon: Icons.groups,
          value: _visits.length.toString(),
          label: 'Patient visits across $clinicCount clinic branch'
              '${clinicCount == 1 ? '' : 'es'}',
        ),
        const SizedBox(height: 14),
        const _SectionLabel('Clinics'),
        const SizedBox(height: 8),
        const _ClinicBranchList(),
        const SizedBox(height: 18),
        const _SectionLabel('Patients Who Visited'),
        const SizedBox(height: 10),
        if (_visits.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "No completed visits yet.",
              style: TextStyle(color: Color(0xFF4F7B55)),
            ),
          )
        else
          ..._visits.map(
            (visit) => _VisitTile(
              leadingText: _initialsFor(visit['patient_name'] as String),
              title: visit['patient_name'] as String,
              subtitle: visit['location'] as String,
              date: _formatVisitDate(
                visit['schedule_date'] as String,
                visit['time_slot'] as String,
              ),
              status: 'Completed',
            ),
          ),
      ],
    );
  }
}

class _PatientVisitHistory extends StatefulWidget {
  const _PatientVisitHistory();

  @override
  State<_PatientVisitHistory> createState() => _PatientVisitHistoryState();
}

class _PatientVisitHistoryState extends State<_PatientVisitHistory> {
  List<Map<String, dynamic>> _visits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = SmartCareSession.currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final visits = await AppointmentService.getVisitHistory(
        userId: userId,
      );
      if (!mounted) return;
      setState(() {
        _visits = visits;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Your Visits'),
        const SizedBox(height: 10),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF0F6B2F)),
            ),
          )
        else if (_visits.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "You don't have any completed visits yet.",
              style: TextStyle(color: Color(0xFF4F7B55)),
            ),
          )
        else
          ..._visits.map(
            (visit) => _VisitTile(
              title: visit['location'] as String,
              subtitle: visit['reference_no'] as String? ?? '',
              date: _formatVisitDate(
                visit['schedule_date'] as String,
                visit['time_slot'] as String,
              ),
              status: 'Completed',
              useClinicIcon: true,
            ),
          ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFB7D7B8)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.health_and_safety,
                color: Color(0xFF0F6B2F),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Keep your health on track!',
                      style: TextStyle(
                        color: Color(0xFF0F6B2F),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Regular checkups help you stay healthy and prevent future health issues.',
                      style: TextStyle(color: Color(0xFF4F7B55), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VisitTile extends StatelessWidget {
  const _VisitTile({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.status,
    this.leadingText,
    this.useClinicIcon = false,
  });

  final String title;
  final String subtitle;
  final String date;
  final String status;
  final String? leadingText;
  final bool useClinicIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB7D7B8)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: useClinicIcon
                  ? const Icon(Icons.location_city, color: Color(0xFF0F6B2F))
                  : (leadingText == null
                        ? const Icon(
                            Icons.event_available,
                            color: Color(0xFF0F6B2F),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              leadingText!,
                              style: const TextStyle(
                                color: Color(0xFF0F6B2F),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F6B2F),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4F7B55),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Center(
            child: _StatusPill(text: status, color: const Color(0xFF2E7D32)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF0F6B2F),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ClinicBranchList extends StatelessWidget {
  const _ClinicBranchList();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _clinicBranches
          .map((clinic) => _ClinicBranchChip(label: clinic))
          .toList(),
    );
  }
}

class _ClinicBranchChip extends StatelessWidget {
  const _ClinicBranchChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB7D7B8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place, color: Color(0xFF0F6B2F), size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0F6B2F),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardDetailHeader extends StatelessWidget {
  const _DashboardDetailHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SmartCareDashboardHeader(title: title, subtitle: subtitle);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 34),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}
