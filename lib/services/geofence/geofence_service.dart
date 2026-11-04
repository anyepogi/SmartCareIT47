import 'dart:convert';

import '../api_config.dart';

enum ClinicPresence { inClinic, onTheWay, notInClinic }

/// What patients see for one clinic on the Doctor Availability card.
/// [etaMinutes] and [distanceKm] are only set when [presence] is
/// [ClinicPresence.onTheWay].
class ClinicAvailability {
  const ClinicAvailability({
    required this.location,
    required this.presence,
    this.etaMinutes,
    this.distanceKm,
  });

  final String location;
  final ClinicPresence presence;
  final int? etaMinutes;
  final double? distanceKm;

  factory ClinicAvailability.fromJson(Map<String, dynamic> json) {
    return ClinicAvailability(
      location: json['location'] as String,
      presence: switch (json['status']) {
        'in_clinic' => ClinicPresence.inClinic,
        'on_the_way' => ClinicPresence.onTheWay,
        _ => ClinicPresence.notInClinic,
      },
      etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}

class DoctorAvailability {
  const DoctorAvailability({required this.doctorName, required this.clinics});

  final String doctorName;
  final Map<String, ClinicAvailability> clinics;
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

    final response = await ApiConfig.post(uri);

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

    final response = await ApiConfig.post(
      uri,
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

    final response = await ApiConfig.post(
      uri,
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

  /* This sends the doctor's current GPS position to the backend. The
  tracking phone calls this every 2 minutes, and the backend uses it to
  work out which clinic the doctor is heading to and refresh the ETA
  patients see on the Doctor Availability card. */
  static Future<void> updatePosition({
    required int userId,
    required double latitude,
    required double longitude,
  }) async {
    await _post('update_position.php', {
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /* This saves the clinic the doctor picked on the Doctor Travel card
  (or clears it when destination is null). The backend then uses this
  clinic for the "On the way" ETA patients see, instead of guessing from
  today's clinic schedule. */
  static Future<void> setTravelDestination({
    required int userId,
    required String? destination,
  }) async {
    await _post('set_travel_destination.php', {
      'user_id': userId,
      'destination': destination,
    });
  }

  /// Returns the clinic the doctor last picked on the Doctor Travel card,
  /// or null if none, so the card survives an app restart.
  static Future<String?> getMyTravelDestination(int userId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/ai_geofence/get_availability.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({'user_id': userId}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load travel destination.');
    }

    return body['travel_destination'] as String?;
  }

  /* Same as updatePosition, but also gives back the ETA the backend
  computed, so the doctor's Doctor Travel card shows exactly the same ETA
  patients see. Both values are null when the backend has no ETA (for
  example the doctor is unavailable or already inside the clinic).
  arrivedAt is the clinic name when this position was inside the clinic
  the doctor was heading to; the backend has then already marked him as
  arrived, cleared his destination, and notified today's patients.
  currentLocation is the clinic the backend has the doctor marked inside
  after this report, or null once he has left it. */
  static Future<
    ({
      int? etaMinutes,
      int? distanceMeters,
      String? arrivedAt,
      String? currentLocation,
    })
  >
  reportTravelPosition({
    required int userId,
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/ai_geofence/update_position.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to report position.');
    }

    return (
      etaMinutes: (body['eta_minutes'] as num?)?.toInt(),
      distanceMeters: (body['eta_distance_m'] as num?)?.toInt(),
      arrivedAt: body['arrived'] == true ? body['arrived_at'] as String? : null,
      currentLocation: body['current_location'] as String?,
    );
  }

  /// Returns the doctor's status at every clinic: in clinic, on the way
  /// (with ETA), or not in clinic.
  static Future<DoctorAvailability> getStatus() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/ai_geofence/get_status.php',
    );

    final response = await ApiConfig.post(uri);

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load doctor status.');
    }

    final clinics = (body['clinics'] as List).map(
      (entry) => ClinicAvailability.fromJson(entry as Map<String, dynamic>),
    );
    return DoctorAvailability(
      doctorName: body['doctor_name'] as String,
      clinics: {for (final clinic in clinics) clinic.location: clinic},
    );
  }

  /// Returns each clinic's persisted target latitude/longitude.
  static Future<Map<String, (double, double)>> getClinicCoordinates() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/ai_geofence/get_clinic_coordinates.php',
    );

    final response = await ApiConfig.post(uri);

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

    final response = await ApiConfig.post(uri, body: jsonEncode(body));

    final Map<String, dynamic> decoded = jsonDecode(response.body);
    if (response.statusCode != 200 || decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Request failed.');
    }
  }
}
