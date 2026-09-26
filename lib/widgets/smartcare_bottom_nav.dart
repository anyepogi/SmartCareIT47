import 'package:flutter/material.dart';

import '../state/app_session.dart';
import 'animated_pressable.dart';

enum SmartCareBottomItem {
  home,
  geofence,
  queue,
  schedule,
  profile,
  visits,
  menu,
}

class SmartCareBottomNav extends StatelessWidget {
  const SmartCareBottomNav({super.key, this.currentItem, this.roleOverride});

  final SmartCareBottomItem? currentItem;
  final UserRole? roleOverride;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserRole>(
      valueListenable: SmartCareSession.role,
      builder: (context, sessionRole, _) {
        final role = roleOverride ?? sessionRole;
        final actions = _actions(role);

        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: SafeArea(
            top: false,
            child: Material(
              color: Colors.white,
              elevation: 10,
              shadowColor: const Color(0x330F6B2F),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 78,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD2E7D1)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: actions.map((action) {
                    final selected = _isSelected(
                      role,
                      currentItem,
                      action.item,
                    );
                    final isCenter = action.item == _centerItem(role);

                    return Expanded(
                      child: isCenter
                          ? _CenterNavButton(
                              action: action,
                              selected: selected,
                              onTap: () => _handleTap(context, action),
                            )
                          : _NavButton(
                              action: action,
                              selected: selected,
                              onTap: () => _handleTap(context, action),
                            ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(BuildContext context, _BottomNavAction action) {
    final routeName = action.routeName;
    if (routeName == null ||
        ModalRoute.of(context)?.settings.name == routeName) {
      return;
    }

    smartCareGoTo(context, routeName, roleToSet: action.roleToSet);
  }

  static List<_BottomNavAction> _actions(UserRole role) {
    if (role != UserRole.patient) {
      return [
        _BottomNavAction(
          item: SmartCareBottomItem.home,
          icon: Icons.home_rounded,
          label: "Home",
          routeName: role.dashboardRoute,
          roleToSet: role,
        ),
        _BottomNavAction(
          item: SmartCareBottomItem.geofence,
          icon: Icons.shield_rounded,
          label: "Geofence",
          routeName: role == UserRole.doctor
              ? '/doctor-view'
              : '/secretary-view',
          roleToSet: role,
        ),
        _BottomNavAction(
          item: SmartCareBottomItem.queue,
          icon: Icons.assignment_rounded,
          label: "Queue",
          routeName: '/queue',
          roleToSet: role,
        ),
        _BottomNavAction(
          item: SmartCareBottomItem.schedule,
          icon: Icons.event_available,
          label: "Schedule",
          routeName: role == UserRole.doctor
              ? '/doctor-schedule'
              : role == UserRole.secretary
              ? '/secretary-schedule'
              : '/appointment',
          roleToSet: role,
        ),
        _BottomNavAction(
          item: SmartCareBottomItem.profile,
          icon: Icons.grid_view_rounded,
          label: "Menu",
          routeName: '/menu-doctor-nurse',
          roleToSet: role,
        ),
      ];
    }

    return [
      _BottomNavAction(
        item: SmartCareBottomItem.home,
        icon: role == UserRole.patient
            ? Icons.home_rounded
            : Icons.dashboard_rounded,
        label: "Home",
        routeName: role.dashboardRoute,
        roleToSet: role,
      ),
      _BottomNavAction(
        item: SmartCareBottomItem.profile,
        icon: role == UserRole.patient ? Icons.person : Icons.badge,
        label: "Profile",
        routeName: '/profile',
        roleToSet: role,
      ),
      const _BottomNavAction(
        item: SmartCareBottomItem.schedule,
        icon: Icons.event_available,
        label: "Book",
        routeName: '/appointment',
      ),
      const _BottomNavAction(
        item: SmartCareBottomItem.visits,
        icon: Icons.history,
        label: "History",
        routeName: '/visits',
      ),
      const _BottomNavAction(
        item: SmartCareBottomItem.menu,
        icon: Icons.grid_view_rounded,
        label: "Menu",
        routeName: '/menu',
      ),
    ];
  }

  static SmartCareBottomItem _centerItem(UserRole role) {
    return role == UserRole.patient
        ? SmartCareBottomItem.schedule
        : SmartCareBottomItem.queue;
  }

  static bool _isSelected(
    UserRole role,
    SmartCareBottomItem? currentItem,
    SmartCareBottomItem? actionItem,
  ) {
    final selectedItem =
        role == UserRole.patient && currentItem == SmartCareBottomItem.queue
        ? SmartCareBottomItem.menu
        : currentItem;

    return selectedItem == actionItem;
  }
}

void smartCareGoTo(
  BuildContext context,
  String routeName, {
  UserRole? roleToSet,
}) {
  if (roleToSet != null) {
    SmartCareSession.switchRole(roleToSet);
  }

  if (ModalRoute.of(context)?.settings.name == routeName) {
    return;
  }

  if (routeName == SmartCareSession.currentRole.dashboardRoute) {
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
    return;
  }

  final dashboardRoute = SmartCareSession.currentRole.dashboardRoute;
  Navigator.pushNamedAndRemoveUntil(
    context,
    routeName,
    (route) => route.settings.name == dashboardRoute,
  );
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.action,
    required this.selected,
    required this.onTap,
  });

  final _BottomNavAction action;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF0F6B2F) : const Color(0xFF6E8D73);

    return AnimatedPressable(
      scale: 0.93,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(action.icon, color: color, size: selected ? 26 : 24),
                  const SizedBox(height: 5),
                  Text(
                    action.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterNavButton extends StatelessWidget {
  const _CenterNavButton({
    required this.action,
    required this.selected,
    required this.onTap,
  });

  final _BottomNavAction action;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final circleColor = selected
        ? const Color(0xFF0F6B2F)
        : const Color(0xFF2E8C44);

    return AnimatedPressable(
      scale: 0.91,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -16,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x330F6B2F),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(action.icon, color: Colors.white, size: 27),
              ),
            ),
            Positioned(
              bottom: 9,
              left: 4,
              right: 4,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  action.label,
                  maxLines: 1,
                  style: TextStyle(
                    color: circleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavAction {
  const _BottomNavAction({
    required this.icon,
    required this.label,
    this.item,
    this.routeName,
    this.roleToSet,
  });

  final SmartCareBottomItem? item;
  final IconData icon;
  final String label;
  final String? routeName;
  final UserRole? roleToSet;
}
