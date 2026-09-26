import 'package:flutter/foundation.dart';

import '../services/auth/session_service.dart';
import 'notification_center.dart';

enum UserRole {
  patient,
  doctor,
  secretary;

  String get label {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.secretary:
        return 'Secretary';
    }
  }

  String get dashboardTitle {
    switch (this) {
      case UserRole.patient:
        return 'Patient Dashboard';
      case UserRole.doctor:
        return 'Doctor Dashboard';
      case UserRole.secretary:
        return 'Secretary Dashboard';
    }
  }

  String get dashboardRoute {
    switch (this) {
      case UserRole.patient:
        return '/dashboard';
      case UserRole.doctor:
        return '/doctor-dashboard';
      case UserRole.secretary:
        return '/secretary-dashboard';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.patient:
        return 'Carise S. Pineda';
      case UserRole.doctor:
        return 'Dr. R. Lim';
      case UserRole.secretary:
        return 'Carise S. Pineda';
    }
  }

  String get initials {
    switch (this) {
      case UserRole.patient:
        return 'CP';
      case UserRole.doctor:
        return 'RL';
      case UserRole.secretary:
        return 'CP';
    }
  }

  bool get canSwitchStaffRole {
    return this == UserRole.doctor || this == UserRole.secretary;
  }
}

class SmartCareSession {
  SmartCareSession._();

  static Map<String, String> personalInfo = {};

  static Map<String, String> medicalInfo = {};

  static final ValueNotifier<UserRole> role = ValueNotifier<UserRole>(
    UserRole.patient,
  );

  static int? currentUserId;
  static String? currentUserEmail;
  static String? currentUserFirstName;
  static String? currentUserLastName;

  static UserRole get currentRole => role.value;

  static bool get isLoggedIn => currentUserId != null;

  static void switchRole(UserRole nextRole) {
    if (role.value == nextRole) {
      return;
    }

    role.value = nextRole;
  }

  static Future<void> setCurrentUser(Map<String, dynamic> user) async {
    // Clear any previously logged-in account's cached profile data so it
    // can never leak into this new session.
    personalInfo = {};
    medicalInfo = {};

    currentUserId = user['user_id'] is int
        ? user['user_id'] as int
        : int.tryParse('${user['user_id']}');
    currentUserEmail = user['email'] as String?;
    currentUserFirstName = user['first_name'] as String?;
    currentUserLastName = user['last_name'] as String?;

    final roleString = user['role'] as String? ?? 'patient';
    switch (roleString) {
      case 'doctor':
        switchRole(UserRole.doctor);
        break;
      case 'secretary':
        switchRole(UserRole.secretary);
        break;
      default:
        switchRole(UserRole.patient);
    }

    await SessionService.save(
      userId: currentUserId ?? 0,
      email: currentUserEmail ?? '',
      firstName: currentUserFirstName ?? '',
      lastName: currentUserLastName ?? '',
      role: roleString,
    );
  }

  /// Restores a previously saved login session, if any.
  /// Returns true when a session was found and restored.
  static Future<bool> restoreSession() async {
    final saved = await SessionService.load();
    if (saved == null) {
      return false;
    }

    currentUserId = saved['user_id'] as int;
    currentUserEmail = saved['email'] as String;
    currentUserFirstName = saved['first_name'] as String;
    currentUserLastName = saved['last_name'] as String;

    switch (saved['role']) {
      case 'doctor':
        switchRole(UserRole.doctor);
        break;
      case 'secretary':
        switchRole(UserRole.secretary);
        break;
      default:
        switchRole(UserRole.patient);
    }

    return true;
  }

  /// Clears the saved session and logs the user out.
  static Future<void> clearSession() async {
    currentUserId = null;
    currentUserEmail = null;
    currentUserFirstName = null;
    currentUserLastName = null;
    personalInfo = {};
    medicalInfo = {};
    switchRole(UserRole.patient);
    NotificationCenter.reset();

    await SessionService.clear();
  }

  static void updatePersonalInfo(String field, String value) {
    personalInfo[field] = value;
  }

  static void updateMedicalInfo(String field, String value) {
    medicalInfo[field] = value;
  }
}
