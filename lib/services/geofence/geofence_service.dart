import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';

class DoctorLocationStatus {
  const DoctorLocationStatus({
    required this.location,
    required this.doctorName,
  });

  final String location;
  final String doctorName;
}

class DoctorAccount {
  const DoctorAccount({required this.userId, required this.name});

  final int userId;
  final String name;
}

class GeofenceService {
  GeofenceService._();

  /// Returns the clinic's doctor account. SmartCare runs a single clinic
  /// with one doctor, so this is who the secretary's Geofencing screen
  /// operates tracking on behalf of.
  static Future<DoctorAccount> getDoctorAccount() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/ai_geofence/get_doctor_account.php',
    );

    final response = await http.post(uri);

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load doctor account.');
    }

    return DoctorAccount(
      userId: body['user_id'] as int,
      name: body['name'] as String,
    );
  }

  /* This asks the backend if the doctor has turned on the "Available"
  switch, and if the geofence has detected them physically inside a
  clinic right now. It gives back two things together: the switch state
  (true or false), and the name of the clinic location if they are
  currently detected inside one, or null if they are not inside any. */
  static Future<(bool, String?)> getMyAvailability(int userId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/ai_geofence/get_availability.php',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load availability.');
    }

    return (body['is_available'] as bool, body['current_location'] as String?);
  }

  /* This turns the doctor's "Available" switch on or off. Patients and
  the secretary use this switch to know if the doctor is open for
  consultations. Turning it off also clears any clinic the doctor was
  marked as being inside of, so patients never see a doctor marked as
  "in clinic" while the doctor has switched themselves off. */
  static Future<void> toggleAvailability({
    required int userId,
    required bool isAvailable,
  }) async {
    await _post('toggle_availability.php', {
      'user_id': userId,
      'is_available': isAvailable,
    });
  }

  /* This tells the backend that GPS tracking just started or stopped,
  and optionally sends the current distance (in meters) from the doctor
  to each clinic. This matters because the doctor and the secretary use
  separate phones. If the doctor starts tracking on his own phone, the
  secretary's phone would not know about it unless it asks the backend.
  So whichever phone is actually running the GPS calls this function,
  and the other phone can check the backend to see the same status. */
  static Future<void> setTrackingStatus({
    required int userId,
    required bool isTracking,
    Map<String, double?>? distances,
  }) async {
    await _post('set_tracking_status.php', {
      'user_id': userId,
      'is_tracking': isTracking,
      if (distances != null) 'distances': distances,
    });
  }

  static Future<void> stopTracking(int userId) async {
    await setTrackingStatus(userId: userId, isTracking: false);
  }

  /* This asks the backend if GPS tracking is currently active for the
  doctor, and the last known distance to each clinic, no matter which
  phone (doctor's or secretary's) is actually doing the tracking. The
  Geofencing screens call this every few seconds so both phones agree
  on what is happening even though only one of them has the real GPS
  signal running. */
  static Future<(bool, Map<String, double?>)> getTrackingStatus(
    int userId,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/ai_geofence/get_tracking_status.php',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load tracking status.');
    }

    final distances = <String, double?>{
      for (final entry in (body['distances'] as Map<String, dynamic>).entries)
        entry.key: (entry.value as num?)?.toDouble(),
    };

    return (body['is_tracking'] as bool, distances);
  }

  /* This tells the backend that the doctor just walked into (or out of)
  the 200 meter circle around a clinic. isInside true means they just
  arrived, false means they just left. The backend only sends a "doctor
  has arrived" notification to patients the first time they enter a
  clinic each day, so patients do not get spammed with notifications if
  the doctor walks in and out many times. */
  static Future<void> updateLocationStatus({
    required int userId,
    required String location,
    required bool isInside,
  }) async {
    await _post('update_location.php', {
      'user_id': userId,
      'location': location,
      'is_inside': isInside,
    });
  }

  /// Returns every clinic location that currently has an available doctor
  /// physically inside its geofence.
  static Future<List<DoctorLocationStatus>> getStatus() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/ai_geofence/get_status.php',
    );

    final response = await http.post(uri);

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load doctor status.');
    }

    return (body['locations'] as List)
        .map(
          (entry) => DoctorLocationStatus(
            location: entry['location'] as String,
            doctorName: entry['doctor_name'] as String,
          ),
        )
        .toList();
  }

  /// Returns each clinic's persisted target latitude/longitude.
  static Future<Map<String, (double, double)>> getClinicCoordinates() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/ai_geofence/get_clinic_coordinates.php',
    );

    final response = await http.post(uri);

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load clinic coordinates.');
    }

    return {
      for (final entry in (body['coordinates'] as List))
        entry['location'] as String: (
          (entry['latitude'] as num).toDouble(),
          (entry['longitude'] as num).toDouble(),
        ),
    };
  }

  /// Persists a clinic's target latitude/longitude.
  static Future<void> updateClinicCoordinates({
    required String location,
    required double latitude,
    required double longitude,
    int? actorUserId,
  }) async {
    await _post('update_clinic_coordinates.php', {
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'actor_user_id': actorUserId,
    });
  }

  static Future<void> _post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/ai_geofence/$endpoint');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final Map<String, dynamic> decoded = jsonDecode(response.body);
    if (response.statusCode != 200 || decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Request failed.');
    }
  }
}
