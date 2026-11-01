import 'package:flutter/material.dart';

import '../services/auth/sign_out_confirmation.dart';
import '../state/app_session.dart';
import '../widgets/animated_pressable.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';

<<<<<<< HEAD
/// Tablet/desktop layouts (wider than 800px) get a 900px container and larger
/// text, like the doctor/secretary menu; phones keep their original sizes.
bool _isTablet(BuildContext context) => MediaQuery.sizeOf(context).width > 800;

=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
            final tablet = _isTablet(context);
=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
            return SingleChildScrollView(
              child: Column(
                children: [
                  const _MenuHeader(),
                  Padding(
<<<<<<< HEAD
                    padding: tablet
                        ? const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          )
                        : const EdgeInsets.fromLTRB(16, 20, 16, 26),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: tablet ? 900 : 720,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _MenuSectionTitle('MAIN', isFirst: true),
=======
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
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
    final tablet = _isTablet(context);
    final titleStyle = TextStyle(
      color: tablet ? Colors.black87 : const Color(0xFF1A3320),
      fontSize: tablet ? 18 : 14,
      fontWeight: tablet ? FontWeight.bold : FontWeight.w600,
    );

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
                  child: subtitle != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
<<<<<<< HEAD
                            Text(title, style: titleStyle),
                            SizedBox(height: tablet ? 3 : 2),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                color: tablet
                                    ? Colors.black54
                                    : const Color(0xFF6E8D73),
                                fontSize: tablet ? 14 : 12,
=======
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
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        )
<<<<<<< HEAD
                      : Text(title, style: titleStyle),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: tablet
                      ? Colors.grey.shade400
                      : const Color(0xFF6E8D73),
                  size: tablet ? 22 : 20,
=======
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
