import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/api_config.dart';
import '../services/auth/session_service.dart';
import '../services/auth/sign_in_services.dart';
import '../services/geofence/location_tracker.dart';
import '../services/geofence/travel_tracker.dart';
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
    final token = user['token'] as String? ?? '';
    ApiConfig.authToken = token.isEmpty ? null : token;

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
      token: token,
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
    ApiConfig.authToken = saved['token'] as String;

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

  /// Clears the saved session and logs the user out, and asks the backend
  /// to delete the login token so it can't be reused.
  static Future<void> clearSession() async {
    // Turn off GPS tracking (and its Android "Tracking your location"
    // notification) if it is still on, for example a secretary who
    // started tracking for the doctor. This runs before the token is
    // cleared, because stopping reports the exit to the server.
    if (LocationTracker.instance.isTracking.value) {
      try {
        await LocationTracker.instance.stop();
      } catch (_) {
        // Logout should never be blocked by this failing.
      }
    }

    final token = ApiConfig.authToken;
    ApiConfig.authToken = null;
    currentUserId = null;
    currentUserEmail = null;
    currentUserFirstName = null;
    currentUserLastName = null;
    personalInfo = {};
    medicalInfo = {};
    switchRole(UserRole.patient);
    NotificationCenter.reset();
    // Stop reporting the doctor's travel ETA so it doesn't keep running
    // (or leak into) the next account that signs in on this phone.
    TravelTracker.instance.reset();

    await SessionService.clear();
    if (token != null) {
      unawaited(SignInService.logout(token));
    }
  }

  static void updatePersonalInfo(String field, String value) {
    personalInfo[field] = value;
  }

  static void updateMedicalInfo(String field, String value) {
    medicalInfo[field] = value;
  }
}
