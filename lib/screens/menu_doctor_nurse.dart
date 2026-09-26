import 'package:flutter/material.dart';

import '../services/auth/sign_out_confirmation.dart';
import '../services/geofence/geofence_service.dart';
import '../services/geofence/location_tracker.dart';
import '../state/app_session.dart';
import '../widgets/animated_pressable.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';

/// Turns the doctor's "Available" toggle off on logout, so patients never
/// see a doctor marked available/in-clinic after they've signed out. A
/// no-op for any other role. Best-effort — logout proceeds either way.
Future<void> _clearDoctorAvailabilityOnLogout() async {
  final userId = SmartCareSession.currentUserId;
  if (SmartCareSession.currentRole != UserRole.doctor || userId == null) {
    return;
  }
  try {
    await LocationTracker.instance.stop();
    await GeofenceService.toggleAvailability(
      userId: userId,
      isAvailable: false,
    );
  } catch (_) {
    // Logout should never be blocked by this failing.
  }
}

class MenuDoctorNursePage extends StatelessWidget {
  const MenuDoctorNursePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F2E4),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.profile,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const _MenuHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 26),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // MAIN Section
                        const Padding(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 12),
                          child: Text(
                            'MAIN',
                            style: TextStyle(
                              color: Color(0xFF6E8D73),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const _MenuItem(
                          icon: Icons.dashboard_rounded,
                          title: "Dashboard",
                          subtitle: "Overview of key metrics and insights",
                          routeName: '/doctor-dashboard',
                        ),
                        const _MenuItem(
                          icon: Icons.event_available,
                          title: "Schedule",
                          subtitle: "View and manage your daily schedule",
                          routeName: '/doctor-schedule',
                        ),
                        const _MenuItem(
                          icon: Icons.person,
                          title: "Profile",
                          subtitle: "Manage your personal information",
                          routeName: '/profile',
                        ),

                        const _MenuItem(
                          icon: Icons.shield_rounded,
                          title: "Geofence",
                          subtitle: "Manage geofence settings and alerts",
                          routeName: '/doctor-view',
                        ),
                        const _MenuItem(
                          icon: Icons.assignment_rounded,
                          title: "Queue Status",
                          subtitle: "View and manage the current queue",
                          routeName: '/queue',
                        ),
                        const _MenuItem(
                          icon: Icons.notifications,
                          title: "Notifications",
                          subtitle: "View alerts, announcements and updates",
                          routeName: '/notifications-doctor-nurse',
                        ),
                        // ADMIN CONTROL HUB Section
                        const _MenuSectionTitle("ADMIN CONTROL HUB"),
                        const _MenuItem(
                          icon: Icons.calendar_today,
                          title: "Appointments",
                          subtitle: "Manage and review appointments",
                          routeName: '/admin-appointments',
                        ),
                        const _MenuItem(
                          icon: Icons.people,
                          title: "User Management",
                          subtitle: "Manage user accounts and roles",
                          routeName: '/user-management',
                        ),
                        const _MenuItem(
                          icon: Icons.history,
                          title: "Audit Logs",
                          subtitle: "View system activity and audit trail",
                          routeName: '/audit-logs',
                        ),
                        // INFORMATION Section
                        const _MenuSectionTitle("INFORMATION"),
                        const _MenuItem(
                          icon: Icons.phone,
                          title: "Contacts",
                          subtitle: "Access important contacts and support",
                          routeName: '/contact-role',
                        ),
                        const _MenuItem(
                          icon: Icons.info,
                          title: "About Us",
                          subtitle: "Learn more about SmartCare",
                          routeName: '/about-role',
                        ),
                        const _MenuItem(
                          icon: Icons.description,
                          title: "Terms and Conditions",
                          subtitle: "Read our terms and conditions",
                          routeName: '/terms-role',
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              final shouldSignOut =
                                  await confirmSmartCareSignOut(context);
                              if (!shouldSignOut || !context.mounted) return;
                              await _clearDoctorAvailabilityOnLogout();
                              await SmartCareSession.clearSession();
                              if (!context.mounted) return;
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/',
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF146F1B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              shadowColor: const Color(
                                0xFF146F1B,
                              ).withOpacity(0.3),
                            ),
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
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

class _MenuHeader extends StatelessWidget {
  const _MenuHeader();

  @override
  Widget build(BuildContext context) {
    return const SmartCareDashboardHeader(
      title: "Menu",
      subtitle: "Access your account, tools, and resources in one place.",
    );
  }
}

class _MenuSectionTitle extends StatelessWidget {
  const _MenuSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF6E8D73),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.routeName,
  }) : roleToSet = null;

  final IconData icon;
  final String title;
  final String subtitle;
  final String routeName;
  final UserRole? roleToSet;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3EFE1), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A000000),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigate(context, routeName, roleToSet: roleToSet),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECF1EE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(icon, color: const Color(0xFF146F1B), size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF1A3320),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF6E8D73),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF6E8D73),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _navigate(BuildContext context, String routeName, {UserRole? roleToSet}) {
  final nextRole = roleToSet;
  if (nextRole != null) {
    SmartCareSession.switchRole(nextRole);
  }

  if (ModalRoute.of(context)?.settings.name == routeName) {
    return;
  }

  Navigator.pushNamed(context, routeName);
}
