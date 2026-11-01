import 'package:flutter/material.dart';

import '../state/app_session.dart';
import '../state/notification_center.dart';
import 'smartcare_bottom_nav.dart';

/// "Good morning" before 12 noon, "Good afternoon" until 6 PM, and
/// "Good evening" after that, by the phone's clock. Used by the patient,
/// doctor, and secretary dashboard headers.
String timeOfDayGreeting([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return "Good morning";
  if (hour < 18) return "Good afternoon";
  return "Good evening";
}

class SmartCareDashboardHeader extends StatelessWidget {
  const SmartCareDashboardHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showNotificationIcon = true,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final bool showNotificationIcon;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
<<<<<<< HEAD
        // Tablets (wider than 800px) get a slightly shorter header with
        // larger text and a bigger bell; phones keep their exact layout.
        final tablet = MediaQuery.sizeOf(context).width > 800;
        final horizontalPadding = tablet ? 24.0 : (compact ? 10.0 : 18.0);
        final titleTopPadding = tablet ? 14.0 : (compact ? 19.0 : 22.0);
        final bottomPadding = tablet ? 0.0 : (compact ? 30.0 : 34.0);

        return Container(
          width: double.infinity,
          height: tablet ? 155 : 175,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage("assets/headnav.png"),
              fit: BoxFit.cover,
              // Tablets trim the shorter header from the bottom so the
              // artwork's top edge stays where it was.
              alignment: tablet ? Alignment.topCenter : Alignment.center,
=======
        final horizontalPadding = compact ? 10.0 : 18.0;
        final titleTopPadding = compact ? 19.0 : 22.0;
        final bottomPadding = compact ? 30.0 : 34.0;

        return Container(
          width: double.infinity,
          height: 175,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/headnav.png"),
              fit: BoxFit.cover,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  6,
                  horizontalPadding,
                  6,
                ),
                child: SizedBox(
<<<<<<< HEAD
                  height: tablet ? 40 : 30,
=======
                  height: 30,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                  child: Row(
                    children: [
                      if (onBack != null)
                        Semantics(
                          button: true,
                          label: "Back",
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onBack,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 5),
                              child: Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      if (onBack != null) const SizedBox(width: 6),
<<<<<<< HEAD
                      Expanded(
=======
                      const Expanded(
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                        child: Text(
                          "SmartCare",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
<<<<<<< HEAD
                            fontSize: tablet ? 21 : 18,
=======
                            fontSize: 18,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                      ),
                      if (showNotificationIcon)
<<<<<<< HEAD
                        _DashboardNotificationButton(large: tablet),
=======
                        const _DashboardNotificationButton(),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0x8CFFFFFF)),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  titleTopPadding,
                  horizontalPadding,
                  bottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
<<<<<<< HEAD
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: tablet ? 24 : 17,
=======
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                        fontWeight: FontWeight.w700,
                        height: 1.08,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
<<<<<<< HEAD
                      SizedBox(height: tablet ? 6 : 5),
                      Text(
                        subtitle,
                        // Tablets are wide enough for one line, which keeps
                        // a two-line title inside the shorter header.
                        maxLines: tablet ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFFE8F7E8),
                          fontSize: tablet ? 15 : 13,
=======
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE8F7E8),
                          fontSize: 13,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                          fontWeight: FontWeight.w400,
                          height: 1.18,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardNotificationButton extends StatelessWidget {
<<<<<<< HEAD
  const _DashboardNotificationButton({this.large = false});

  /// Tablet sizing: bigger bell, tap area and badge.
  final bool large;
=======
  const _DashboardNotificationButton();
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: "Notifications",
      padding: EdgeInsets.zero,
<<<<<<< HEAD
      constraints: BoxConstraints.tightFor(
        width: large ? 40 : 30,
        height: large ? 40 : 30,
      ),
=======
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
      onPressed: () {
        final currentRole = SmartCareSession.currentRole;
        final route =
            currentRole == UserRole.doctor || currentRole == UserRole.secretary
            ? '/notifications-doctor-nurse'
            : '/notifications';
        smartCareGoTo(context, route);
      },
      icon: ValueListenableBuilder<int>(
        valueListenable: NotificationCenter.unreadCount,
        builder: (context, unreadCount, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
<<<<<<< HEAD
              Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: large ? 30 : 23,
=======
              const Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 23,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
<<<<<<< HEAD
                    width: large ? 17 : 14,
                    height: large ? 17 : 14,
=======
                    width: 14,
                    height: 14,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF304B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.4),
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
<<<<<<< HEAD
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: large ? 8.5 : 7,
=======
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
