import 'package:flutter/material.dart';
import '../services/profile/profile_service.dart';
import '../state/app_session.dart';
import '../widgets/profile_field_pickers.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  bool _personalInfoExpanded = true;
  bool _settingsExpanded = false;
  late Map<String, String> _editedPersonalInfo;

  @override
  void initState() {
    super.initState();
    _editedPersonalInfo = {};
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = SmartCareSession.currentUserId;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _loadError = 'No logged-in user found.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final profile = await ProfileService.getProfile(userId);
      SmartCareSession.personalInfo.addAll({
        'First Name': profile['first_name'] as String? ?? '',
        'Middle Name': profile['middle_name'] as String? ?? '',
        'Last Name': profile['last_name'] as String? ?? '',
        'Date of Birth': profile['date_of_birth'] as String? ?? '',
        'Gender': profile['gender'] as String? ?? '',
        'Email': profile['email'] as String? ?? '',
        'Phone': profile['contact_number'] as String? ?? '',
        'Address': profile['address'] as String? ?? '',
        'Civil Status': profile['civil_status'] as String? ?? '',
        'Occupation': profile['occupation'] as String? ?? '',
        'Emergency Contact': profile['emergency_contact'] as String? ?? '',
      });
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _initializeEditMode() {
    _editedPersonalInfo = Map.from(
      SmartCareSession.personalInfo.cast<String, String>(),
    );
  }

  Future<bool> _saveChanges() async {
    final userId = SmartCareSession.currentUserId;
    if (userId == null) {
      return false;
    }

    setState(() {
      _isSaving = true;
    });

    final merged = {...SmartCareSession.personalInfo, ..._editedPersonalInfo};

    try {
      final updated = await ProfileService.updateProfile(
        userId: userId,
        firstName: merged['First Name'] ?? '',
        middleName: merged['Middle Name'] ?? '',
        lastName: merged['Last Name'] ?? '',
        dateOfBirth: merged['Date of Birth'] ?? '',
        contactNumber: merged['Phone'] ?? '',
        gender: merged['Gender'] ?? '',
        occupation: merged['Occupation'] ?? '',
        civilStatus: merged['Civil Status'] ?? '',
        emergencyContact: merged['Emergency Contact'] ?? '',
        address: merged['Address'] ?? '',
      );

      SmartCareSession.personalInfo.addAll({
        'First Name': updated['first_name'] as String? ?? '',
        'Middle Name': updated['middle_name'] as String? ?? '',
        'Last Name': updated['last_name'] as String? ?? '',
        'Date of Birth': updated['date_of_birth'] as String? ?? '',
        'Gender': updated['gender'] as String? ?? '',
        'Phone': updated['contact_number'] as String? ?? '',
        'Address': updated['address'] as String? ?? '',
        'Civil Status': updated['civil_status'] as String? ?? '',
        'Occupation': updated['occupation'] as String? ?? '',
        'Emergency Contact': updated['emergency_contact'] as String? ?? '',
      });
      _editedPersonalInfo.clear();

      if (!mounted) return true;
      setState(() {
        _isSaving = false;
      });
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return false;
    }
  }

  void _cancelChanges() {
    _editedPersonalInfo.clear();
  }

  String _getDisplayValue(String key) {
    return _editedPersonalInfo[key] ?? SmartCareSession.personalInfo[key] ?? '';
  }

  String _fullName() {
    final first = SmartCareSession.personalInfo['First Name'] ?? '';
    final last = SmartCareSession.personalInfo['Last Name'] ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? SmartCareSession.currentRole.displayName : name;
  }

  String _initialsFromName() {
    final parts = _fullName().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _patientIdLabel() {
    final id = SmartCareSession.currentUserId;
    if (id == null) return 'User ID: -----';
    return 'User ID: ${id.toString().padLeft(5, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F2E4),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.profile,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 12.0 : 16.0;

            if (_isLoading) {
              return ListView(
                children: [
                  const SmartCareDashboardHeader(
                    title: "Patient Profile",
                    subtitle:
                        "View and manage your personal healthcare information.",
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF006B2D),
                      ),
                    ),
                  ),
                ],
              );
            }

            if (_loadError != null) {
              return ListView(
                children: [
                  const SmartCareDashboardHeader(
                    title: "Patient Profile",
                    subtitle:
                        "View and manage your personal healthcare information.",
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF8B2F2F)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006B2D),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView(
              children: [
                const SmartCareDashboardHeader(
                  title: "Patient Profile",
                  subtitle:
                      "View and manage your personal healthcare information.",
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    14,
                    horizontalPadding,
                    22,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Header with Avatar and Info
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFB7D7B8),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Avatar
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4E8D4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _initialsFromName(),
                                      style: const TextStyle(
                                        color: Color(0xFF0F6B2F),
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Name and ID
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _fullName().toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFF0F6B2F),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _patientIdLabel(),
                                        style: const TextStyle(
                                          color: Color(0xFF0F6B2F),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Personal Information Section
                          _ExpandableSection(
                            title: 'Personal Information',
                            isExpanded: _personalInfoExpanded,
                            onExpanded: (value) {
                              setState(() => _personalInfoExpanded = value);
                            },
                            children: [
                              _ProfileInfoField(
                                icon: Icons.person,
                                label: 'First Name',
                                value: _getDisplayValue('First Name'),
                                isEditing: _isEditing,
                                onChanged: (value) => setState(
                                  () =>
                                      _editedPersonalInfo['First Name'] = value,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _ProfileInfoField(
                                icon: Icons.person,
                                label: 'Middle Name',
                                value: _getDisplayValue('Middle Name'),
                                isEditing: _isEditing,
                                onChanged: (value) => setState(
                                  () => _editedPersonalInfo['Middle Name'] =
                                      value,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _ProfileInfoField(
                                icon: Icons.person,
                                label: 'Last Name',
                                value: _getDisplayValue('Last Name'),
                                isEditing: _isEditing,
                                onChanged: (value) => setState(
                                  () =>
                                      _editedPersonalInfo['Last Name'] = value,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ProfileDateField(
                                icon: Icons.calendar_today,
                                label: 'Date of Birth',
                                value: _getDisplayValue('Date of Birth'),
                                isEditing: _isEditing,
                                onChanged: (value) => setState(
                                  () => _editedPersonalInfo['Date of Birth'] =
                                      value,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ProfileGenderField(
                                icon: Icons.wc,
                                label: 'Gender',
                                value: _getDisplayValue('Gender'),
                                isEditing: _isEditing,
                                onChanged: (value) => setState(
                                  () => _editedPersonalInfo['Gender'] = value,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _ProfileInfoField(
                                icon: Icons.email,
                                label: 'Email',
                                value: _getDisplayValue('Email'),
                                isEditing: false,
                              ),
                              const SizedBox(height: 8),
                              _ProfileInfoField(
                                icon: Icons.phone,
                                label: 'Phone Number',
                                value: _getDisplayValue('Phone'),
                                isEditing: _isEditing,
                                onChanged: (value) => setState(
                                  () => _editedPersonalInfo['Phone'] = value,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _ProfileInfoField(
                                icon: Icons.location_on,
                                label: 'Address',
                                value: _getDisplayValue('Address'),
                                isEditing: _isEditing,
                                onChanged: (value) => setState(
                                  () => _editedPersonalInfo['Address'] = value,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _ProfileInfoField(
                                icon: Icons.favorite,
                                label: 'Civil Status',
                                value: _getDisplayValue('Civil Status'),
                                isEditing: _isEditing,
                                onChanged: (value) => setState(
                                  () => _editedPersonalInfo['Civil Status'] =
                                      value,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _ProfileInfoField(
                                icon: Icons.work,
                                label: 'Occupation',
                                value: _getDisplayValue('Occupation'),
                                isEditing: _isEditing,
                                onChanged: (value) => setState(
                                  () =>
                                      _editedPersonalInfo['Occupation'] = value,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _ProfileInfoField(
                                icon: Icons.person,
                                label: 'Emergency Contact',
                                value: _getDisplayValue('Emergency Contact'),
                                isEditing: _isEditing,
                                onChanged: (value) => setState(
                                  () =>
                                      _editedPersonalInfo['Emergency Contact'] =
                                          value,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Settings Section
                          _ExpandableSection(
                            title: 'Settings',
                            isExpanded: _settingsExpanded,
                            onExpanded: (value) {
                              setState(() => _settingsExpanded = value);
                            },
                            children: [
                              _SettingsTile(
                                icon: Icons.privacy_tip,
                                title: 'Privacy and Security',
                                onTap: () => _navigateToAdminPage(
                                  context,
                                  '/privacy-security',
                                ),
                              ),
                              const SizedBox(height: 8),
                              _SettingsTile(
                                icon: Icons.notifications_active,
                                title: 'Notification Settings',
                                onTap: () => _navigateToAdminPage(
                                  context,
                                  '/notification-settings',
                                ),
                              ),
                              const SizedBox(height: 8),
                              _SettingsTile(
                                icon: Icons.lock_outline,
                                title: 'Change Password',
                                onTap: () => _navigateToAdminPage(
                                  context,
                                  '/change-password',
                                ),
                              ),
                              const SizedBox(height: 8),
                              _SettingsTile(
                                icon: Icons.help_outline,
                                title: 'Help and Support',
                                onTap: () => _navigateToAdminPage(
                                  context,
                                  '/help-support',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Edit/Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () async {
                                      if (_isEditing) {
                                        final success = await _saveChanges();
                                        if (!success) return;
                                        setState(() {
                                          _isEditing = false;
                                        });
                                      } else {
                                        setState(() {
                                          _isEditing = true;
                                          _personalInfoExpanded = true;
                                          _initializeEditMode();
                                        });
                                      }
                                    },
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      _isEditing
                                          ? Icons.save_rounded
                                          : Icons.edit_rounded,
                                      size: 20,
                                    ),
                              label: Text(
                                _isSaving
                                    ? 'Saving...'
                                    : (_isEditing
                                          ? 'Save Changes'
                                          : 'Edit Profile'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF006B2D),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          if (_isEditing) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _cancelChanges();
                                  setState(() => _isEditing = false);
                                },
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Cancel'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF006B2D),
                                  side: const BorderSide(
                                    color: Color(0xFF006B2D),
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final ValueChanged<bool> onExpanded;
  final List<Widget> children;

  const _ExpandableSection({
    required this.title,
    required this.isExpanded,
    required this.onExpanded,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB7D7B8)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => onExpanded(!isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.person, color: const Color(0xFF006B2D), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF006B2D),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF006B2D),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFB7D7B8)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: children),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileInfoField extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isEditing;
  final ValueChanged<String>? onChanged;

  const _ProfileInfoField({
    required this.icon,
    required this.label,
    required this.value,
    required this.isEditing,
    this.onChanged,
  });

  @override
  State<_ProfileInfoField> createState() => _ProfileInfoFieldState();
}

class _ProfileInfoFieldState extends State<_ProfileInfoField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_ProfileInfoField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !widget.isEditing) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isEditing
              ? const Color(0xFF006B2D)
              : const Color(0xFFE0E0E0),
          width: widget.isEditing ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: const Color(0xFF006B2D), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: widget.isEditing
                ? TextField(
                    controller: _controller,
                    onChanged: widget.onChanged,
                    style: const TextStyle(
                      color: Color(0xFF006B2D),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: widget.label,
                      labelStyle: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.value.isEmpty ? 'Not provided' : widget.value,
                        style: const TextStyle(
                          color: Color(0xFF006B2D),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF006B2D), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF006B2D),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF006B2D),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _navigateToAdminPage(BuildContext context, String routeName) {
  if (ModalRoute.of(context)?.settings.name == routeName) {
    return;
  }

  Navigator.pushReplacementNamed(context, routeName);
}
