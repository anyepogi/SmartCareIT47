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

<<<<<<< HEAD
/// Tablet/desktop layouts (wider than 800px) get a 900px container and larger
/// text; phones keep their original sizes.
bool _isTablet(BuildContext context) => MediaQuery.sizeOf(context).width > 800;

=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
class MenuDoctorNursePage extends StatelessWidget {
  const MenuDoctorNursePage({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final tablet = _isTablet(context);

=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
                padding: tablet
                    ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
                    : const EdgeInsets.fromLTRB(16, 20, 16, 26),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: tablet ? 900 : 720),
=======
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 26),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // MAIN Section
<<<<<<< HEAD
                        const _MenuSectionTitle("MAIN", isFirst: true),
=======
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
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
                        SizedBox(height: tablet ? 32 : 24),
                        SizedBox(
                          width: double.infinity,
                          height: tablet ? 52 : 48,
=======
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
                                borderRadius: BorderRadius.circular(
                                  tablet ? 16 : 10,
                                ),
=======
                                borderRadius: BorderRadius.circular(10),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                              ),
                              elevation: 2,
                              shadowColor: const Color(
                                0xFF146F1B,
                              ).withOpacity(0.3),
                            ),
<<<<<<< HEAD
                            child: Text(
                              'Sign Out',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: tablet ? 17 : 14,
                                fontWeight: tablet
                                    ? FontWeight.bold
                                    : FontWeight.w600,
=======
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
  const _MenuSectionTitle(this.title, {this.isFirst = false});

  final String title;

  /// The first section sits right under the page padding, so it gets less
  /// top space than the sections below it.
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    if (_isTablet(context)) {
      return Padding(
        padding: EdgeInsets.only(top: isFirst ? 8 : 24, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF006D38),
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(0, isFirst ? 0 : 20, 0, 12),
=======
  const _MenuSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
    final tablet = _isTablet(context);

=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
            padding: EdgeInsets.symmetric(
              horizontal: tablet ? 20 : 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: tablet ? 46 : 40,
                  height: tablet ? 46 : 40,
                  decoration: BoxDecoration(
                    color: tablet
                        ? const Color(0xFFEAF7EA)
                        : const Color(0xFFECF1EE),
                    borderRadius: BorderRadius.circular(tablet ? 12 : 8),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: const Color(0xFF146F1B),
                      size: tablet ? 25 : 20,
                    ),
                  ),
                ),
                SizedBox(width: tablet ? 16 : 12),
=======
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
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
<<<<<<< HEAD
                        style: TextStyle(
                          color: tablet
                              ? Colors.black87
                              : const Color(0xFF1A3320),
                          fontSize: tablet ? 18 : 14,
                          fontWeight: tablet
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: tablet ? 3 : 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: tablet
                              ? Colors.black54
                              : const Color(0xFF6E8D73),
                          fontSize: tablet ? 14 : 12,
=======
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
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
<<<<<<< HEAD
                Icon(
                  Icons.chevron_right,
                  color: tablet
                      ? Colors.grey.shade400
                      : const Color(0xFF6E8D73),
                  size: tablet ? 22 : 20,
=======
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF6E8D73),
                  size: 20,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
