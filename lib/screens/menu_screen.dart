import 'package:flutter/material.dart';

import '../services/auth/sign_out_confirmation.dart';
import '../state/app_session.dart';
import '../widgets/animated_pressable.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F2E4),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.menu,
      ),
      body: SafeArea(
        child: ValueListenableBuilder<UserRole>(
          valueListenable: SmartCareSession.role,
          builder: (context, role, _) {
            return SingleChildScrollView(
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
                            _MenuItem(
                              icon: Icons.dashboard_rounded,
                              title: 'Dashboard',
                              subtitle:
                                  'Overview of your health and appointments',
                              routeName: role.dashboardRoute,
                              roleToSet: role,
                            ),
                            const _MenuItem(
                              icon: Icons.person,
                              title: 'Profile',
                              subtitle: 'Manage your personal information',
                              routeName: '/profile',
                            ),
                            const _MenuItem(
                              icon: Icons.event_available,
                              title: 'Book Appointment',
                              subtitle: 'Schedule an appointment with a doctor',
                              routeName: '/appointment',
                            ),
                            const _MenuItem(
                              icon: Icons.groups,
                              title: 'Queue Status',
                              subtitle: 'Check your current queue status',
                              routeName: '/queue',
                            ),
                            const _MenuItem(
                              icon: Icons.history,
                              title: 'Visit History',
                              subtitle: 'View your past visits and records',
                              routeName: '/visits',
                            ),
                            const _MenuItem(
                              icon: Icons.notifications,
                              title: 'Notifications',
                              subtitle: 'View alerts and announcements',
                              routeName: '/notifications',
                            ),
                            const _MenuSectionTitle('INFORMATION'),
                            const _MenuItem(
                              icon: Icons.phone,
                              title: 'Contacts',
                              subtitle: 'Access important contacts and support',
                              routeName: '/contact-role',
                            ),
                            const _MenuItem(
                              icon: Icons.info,
                              title: 'About Us',
                              subtitle: 'Learn more about SmartCare',
                              routeName: '/about-role',
                            ),
                            const _MenuItem(
                              icon: Icons.description,
                              title: 'Terms and Conditions',
                              subtitle: 'Read our terms and conditions',
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
                                  if (!shouldSignOut || !context.mounted)
                                    return;
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
            );
          },
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

class _StaffRoleSwitcher extends StatelessWidget {
  const _StaffRoleSwitcher({required this.currentRole});

  final UserRole currentRole;

  @override
  Widget build(BuildContext context) {
    const roles = [UserRole.doctor, UserRole.secretary];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB7D7B8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Switch Staff Role",
            style: TextStyle(
              color: Color(0xFF146F1B),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 320 ? 1 : 2;
              final spacing = columns == 1 ? 0.0 : 10.0;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: 10,
                children: roles.map((role) {
                  final selected = currentRole == role;
                  return SizedBox(
                    width: itemWidth,
                    height: 42,
                    child: AnimatedPressable(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          SmartCareSession.switchRole(role);
                          Navigator.pushReplacementNamed(
                            context,
                            role.dashboardRoute,
                          );
                        },
                        icon: Icon(
                          role == UserRole.doctor
                              ? Icons.local_hospital
                              : Icons.support_agent,
                          size: 18,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(role.label),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selected
                              ? const Color(0xFF146F1B)
                              : const Color(0xFFA4D98D),
                          foregroundColor: selected
                              ? Colors.white
                              : const Color(0xFF146F1B),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
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
    required this.routeName,
    this.subtitle,
    this.roleToSet,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
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
                  child: subtitle != null
                      ? Column(
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
                              subtitle!,
                              style: const TextStyle(
                                color: Color(0xFF6E8D73),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF1A3320),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
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
