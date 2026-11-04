import 'package:flutter/material.dart';
import '../services/auth/change_password_service.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingsPage(
      title: "Privacy and Security",
      subtitle: "Manage account protection and privacy preferences.",
      children: [
        _SettingSwitchTile(
          icon: Icons.lock,
          title: "Two-step verification",
          subtitle: "Add another layer of account protection.",
        ),
        _SettingSwitchTile(
          icon: Icons.location_on,
          title: "Location access",
          subtitle: "Allow SmartCare to support geofencing features.",
        ),
        _SettingInfoTile(
          icon: Icons.verified_user,
          title: "Login activity",
          subtitle: "Last sign in: Today at 4:27 PM",
        ),
        _SettingInfoTile(
          icon: Icons.privacy_tip,
          title: "Data protection",
          subtitle: "Your information is used only for healthcare services.",
        ),
      ],
    );
  }
}

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingsPage(
      title: "Notification Settings",
      subtitle: "Choose which reminders and updates you want to receive.",
      children: [
        _SettingSwitchTile(
          icon: Icons.calendar_month,
          title: "Appointment reminders",
          subtitle: "Receive alerts before scheduled appointments.",
        ),
        _SettingSwitchTile(
          icon: Icons.groups,
          title: "Queue updates",
          subtitle: "Get notified when your queue status changes.",
        ),
        _SettingSwitchTile(
          icon: Icons.local_hospital,
          title: "Doctor arrival alerts",
          subtitle: "Know when your doctor arrives in the clinic.",
        ),
        _SettingSwitchTile(
          icon: Icons.campaign,
          title: "System announcements",
          subtitle: "Receive important SmartCare notices.",
        ),
      ],
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Checks the same rules as change_password.php before sending, so
  /// simple mistakes are shown right away.
  String? _validate() {
    final newPassword = _new.text.trim();
    if (_current.text.isEmpty || newPassword.isEmpty || _confirm.text.isEmpty) {
      return "Please fill in all three fields.";
    }
    if (newPassword.length < 8 || !RegExp(r'\d').hasMatch(newPassword)) {
      return "Password must be at least 8 characters and include a number.";
    }
    if (newPassword != _confirm.text.trim()) {
      return "New password and confirmation don't match.";
    }
    return null;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ChangePasswordService.changePassword(
        currentPassword: _current.text,
        newPassword: _new.text.trim(),
      );
      if (!mounted) return;
      _current.clear();
      _new.clear();
      _confirm.clear();
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully.")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsPage(
      title: "Change Password",
      subtitle: "Update your password to keep your account secure.",
      children: [
        _PasswordField(label: "Current Password", controller: _current),
        _PasswordField(label: "New Password", controller: _new),
        _PasswordField(label: "Confirm New Password", controller: _confirm),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "At least 8 characters, with at least one number.",
            style: TextStyle(color: Color(0xFF4F7B55), fontSize: 12),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF146F1B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    "Update Password",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingsPage(
      title: "Help and Support",
      subtitle: "Find help for appointments, queues, and account concerns.",
      children: [
        _SettingInfoTile(
          icon: Icons.help,
          title: "Frequently asked questions",
          subtitle: "View common SmartCare questions and answers.",
        ),
        _SettingInfoTile(
          icon: Icons.phone,
          title: "Call support",
          subtitle: "+63 912 345 6789",
        ),
        _SettingInfoTile(
          icon: Icons.email,
          title: "Email support",
          subtitle: "support@smartcare.ph",
        ),
        _SettingInfoTile(
          icon: Icons.chat_bubble,
          title: "Send feedback",
          subtitle: "Tell us how we can improve SmartCare.",
        ),
      ],
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDECD9),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.menu,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(title: title, subtitle: subtitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF146F1B)),
                    ),
                    child: Column(children: children),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SmartCareDashboardHeader(title: title, subtitle: subtitle);
  }
}

class _SettingSwitchTile extends StatefulWidget {
  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  State<_SettingSwitchTile> createState() => _SettingSwitchTileState();
}

class _SettingSwitchTileState extends State<_SettingSwitchTile> {
  bool isEnabled = true;

  @override
  Widget build(BuildContext context) {
    return _SettingTileShell(
      icon: widget.icon,
      title: widget.title,
      subtitle: widget.subtitle,
      trailing: Switch(
        value: isEnabled,
        activeThumbColor: const Color(0xFF146F1B),
        onChanged: (value) {
          setState(() {
            isEnabled = value;
          });
        },
      ),
    );
  }
}

class _SettingInfoTile extends StatelessWidget {
  const _SettingInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _SettingTileShell(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF146F1B)),
    );
  }
}

class _SettingTileShell extends StatelessWidget {
  const _SettingTileShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD2E7D1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: const Color(0xFFDDECD9),
            child: Icon(icon, color: const Color(0xFF146F1B), size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF146F1B),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF4F7B55),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF146F1B)),
          prefixIcon: const Icon(Icons.lock, color: Color(0xFF146F1B)),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6DA36D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF146F1B), width: 2),
          ),
        ),
      ),
    );
  }
}
