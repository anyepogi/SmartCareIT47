import 'dart:async';

import 'package:flutter/material.dart';

import 'chatbot.dart';
import 'screens/profile_patient_screen.dart';
import 'screens/doctor_profile_screen.dart';
import 'screens/secretary_profile_screen.dart';
import 'screens/about_us_screen.dart';
import 'screens/about_us_role.dart';
import 'screens/appointment_screen.dart';
import 'screens/audit.dart';
import 'screens/all_upcoming_appointments_screen.dart';
import 'screens/cancelled.dart';
import 'screens/confirm.dart';
import 'screens/contact_us_screen.dart';
import 'screens/contact_role.dart';
import 'screens/dashboard_screen.dart';
import 'screens/doctor_dashboard_screen.dart';
import 'screens/doctor_schedule_screen.dart';
import 'screens/doctor_geofence_screen.dart';
import 'screens/doctor_queue_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/menu_doctor_nurse.dart';
import 'screens/notification.dart';
import 'screens/notification_doctor_nurse.dart';
import 'screens/queue_status.dart';
import 'screens/role_appointment.dart';
import 'screens/secretary_dashboard_screen.dart';
import 'screens/secretary_geofence_screen.dart';
import 'screens/secretary_queue_screen.dart';
import 'screens/secretary_schedule_screen.dart';
import 'screens/settings_pages.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/terms_condition_screen.dart';
import 'screens/terms_condition_role.dart';
import 'screens/user_management.dart';
import 'screens/visit_history_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/notifications/appointment_reminder_service.dart';
import 'services/navigation_transitions.dart';
import 'state/app_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final loggedIn = await SmartCareSession.restoreSession();
  final initialRoute = loggedIn
      ? SmartCareSession.currentRole.dashboardRoute
      : '/';

  await AppointmentReminderService.initialize();
  if (loggedIn) {
    unawaited(AppointmentReminderService.requestPermissions());
  }

  runApp(SmartCareApp(initialRoute: initialRoute));
}

class SmartCareApp extends StatelessWidget {
  const SmartCareApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartCare',
      theme: _buildTheme(),
      initialRoute: initialRoute,
      onGenerateRoute: _createRoute,
    );
  }

  Route<dynamic> _createRoute(RouteSettings settings) {
    final page = _pageForRoute(settings.name);
    return smartCareRoute(
      settings: settings,
      transition: _transitionForRoute(settings.name),
      builder: (_) => page,
    );
  }

  SmartCareTransition _transitionForRoute(String? routeName) {
    const authRoutes = {
      '/',
      '/dashboard',
      '/doctor-dashboard',
      '/secretary-dashboard',
    };
    const subPageRoutes = {
      '/sign-in',
      '/sign-up',
      '/forgot-password',
      '/about',
      '/about-role',
      '/contact',
      '/contact-role',
      '/terms',
      '/terms-role',
      '/cancelled',
      '/confirm',
      '/upcoming-appointments',
      '/chatbot',
      '/privacy-security',
      '/notification-settings',
      '/change-password',
      '/help-support',
      '/user-management',
      '/audit-logs',
      '/admin-appointments',
    };

    if (authRoutes.contains(routeName)) {
      return SmartCareTransition.auth;
    }
    if (subPageRoutes.contains(routeName)) {
      return SmartCareTransition.subPage;
    }
    return SmartCareTransition.appear;
  }

  Widget _pageForRoute(String? routeName) {
    switch (routeName) {
      case '/':
        return const WelcomeScreen();
      case '/sign-in':
        return const SignInScreen();
      case '/sign-up':
        return const SignUpScreen();
      case '/forgot-password':
        return const ForgotPasswordScreen();
      case '/dashboard':
        SmartCareSession.switchRole(UserRole.patient);
        return const DashboardScreen();
      case '/chatbot':
        return const ChatbotScreen();
      case '/cancelled':
        return const AppointmentCancelledScreen();
      case '/upcoming-appointments':
        return const AllUpcomingAppointmentsScreen();
      case '/profile':
        if (SmartCareSession.currentRole == UserRole.doctor) {
          return const DoctorProfileScreen();
        }
        if (SmartCareSession.currentRole == UserRole.secretary) {
          return const SecretaryProfileScreen();
        }
        return const PatientProfileScreen();
      case '/appointment':
        return const AppointmentBookingScreen();
      case '/confirm':
        return const AppointmentConfirmScreen();
      case '/queue':
        if (SmartCareSession.currentRole == UserRole.doctor) {
          return const DoctorQueueScreen();
        }
        if (SmartCareSession.currentRole == UserRole.secretary) {
          return const SecretaryQueueScreen();
        }
        return const QueueStatusPage();
      case '/visits':
        return const VisitHistoryScreen();

      case '/notifications':
        return const NotificationsPage();
      case '/notifications-doctor-nurse':
        return const NotificationDoctorNursePage();
      case '/menu':
        return const MenuScreen();
      case '/doctor-view':
        SmartCareSession.switchRole(UserRole.doctor);
        return const DoctorGeofenceScreen();
      case '/secretary-view':
        SmartCareSession.switchRole(UserRole.secretary);
        return const SecretaryGeofenceScreen();
      case '/doctor-dashboard':
        SmartCareSession.switchRole(UserRole.doctor);
        return const DoctorDashboardScreen();
      case '/doctor-schedule':
        SmartCareSession.switchRole(UserRole.doctor);
        return const DoctorScheduleScreen();
      case '/secretary-schedule':
        SmartCareSession.switchRole(UserRole.secretary);
        return const SecretaryScheduleScreen();
      case '/secretary-dashboard':
        SmartCareSession.switchRole(UserRole.secretary);
        return const SecretaryDashboardScreen();
      case '/menu-doctor-nurse':
        return const MenuDoctorNursePage();
      case '/privacy-security':
        return const PrivacySecurityScreen();
      case '/notification-settings':
        return const NotificationSettingsScreen();
      case '/change-password':
        return const ChangePasswordScreen();
      case '/help-support':
        return const HelpSupportScreen();
      case '/contact':
        return const ContactUsScreen();
      case '/contact-role':
        return const ContactRoleScreen();
      case '/about':
        return const AboutUsScreen();
      case '/about-role':
        return const AboutUsRoleScreen();
      case '/terms':
        return const TermsConditionsScreen();
      case '/terms-role':
        return const TermsConditionsRoleScreen();
      case '/user-management':
        return const UserManagementScreen();
      case '/audit-logs':
        return const AuditLogsScreen();
      case '/admin-appointments':
        return const RoleAppointmentScreen();
      default:
        return const WelcomeScreen();
    }
  }
}

ThemeData _buildTheme() {
  const primary = Color(0xFF146F1B);
  const secondary = Color(0xFF2E8C44);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: const Color(0xFFF8FBF5),
    ),
    splashFactory: InkRipple.splashFactory,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        animationDuration: const Duration(milliseconds: 180),
        overlayColor: _stateOverlay(Colors.white, pressed: 0.22, hovered: 0.10),
        elevation: WidgetStateProperty.resolveWith<double?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return 0;
          }
          if (states.contains(WidgetState.pressed)) {
            return 1;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return 5;
          }
          return null;
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        animationDuration: const Duration(milliseconds: 180),
        overlayColor: _stateOverlay(primary),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        animationDuration: const Duration(milliseconds: 180),
        overlayColor: _stateOverlay(primary),
        side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
          if (states.contains(WidgetState.pressed)) {
            return const BorderSide(color: secondary, width: 1.5);
          }
          return null;
        }),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        animationDuration: const Duration(milliseconds: 160),
        overlayColor: _stateOverlay(primary, pressed: 0.18),
      ),
    ),
  );
}

WidgetStateProperty<Color?> _stateOverlay(
  Color color, {
  double pressed = 0.14,
  double hovered = 0.08,
  double focused = 0.10,
}) {
  return WidgetStateProperty.resolveWith<Color?>((states) {
    if (states.contains(WidgetState.pressed)) {
      return Color.lerp(Colors.transparent, color, pressed);
    }
    if (states.contains(WidgetState.hovered)) {
      return Color.lerp(Colors.transparent, color, hovered);
    }
    if (states.contains(WidgetState.focused)) {
      return Color.lerp(Colors.transparent, color, focused);
    }
    return null;
  });
}
