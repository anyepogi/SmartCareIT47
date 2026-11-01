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

  /// The doctor's account. There's only one doctor, so this is who the
  /// secretary's Geofencing screen tracks for.
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

  /// The doctor's Available switch, and the clinic they're inside right
  /// now (null if none).
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

  /// Turns the doctor's Available switch on or off. Turning it off also
  /// clears the clinic they're marked inside, so patients don't see
  /// "In Clinic" for an unavailable doctor.
  static Future<void> toggleAvailability({
    required int userId,
    required bool isAvailable,
  }) async {
    await _post('toggle_availability.php', {
      'user_id': userId,
      'is_available': isAvailable,
    });
  }

  /// Tells the backend that tracking started or stopped, with optional
  /// distances to each clinic. The doctor and secretary use different
  /// phones, so this is how the other phone knows tracking is on.
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

  /// Whether tracking is on (from either phone) and the last distance to
  /// each clinic. The Geofencing screens poll this.
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

  /// Reports the doctor entering (isInside true) or leaving a clinic's
  /// 200 m radius. Patients are only notified on the first arrival of
  /// the day.
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

  /// Sends the doctor's GPS position so the backend can update the ETA
  /// patients see. Called every 2 minutes while tracking.
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

  /// Saves the clinic picked on the Doctor Travel card, or clears it when
  /// destination is null. The patients' ETA uses this clinic.
  static Future<void> setTravelDestination({
    required int userId,
    required String? destination,
  }) async {
    await _post('set_travel_destination.php', {
      'user_id': userId,
      'destination': destination,
    });
  }

  /// The clinic picked on the Doctor Travel card, or null. Used to bring
  /// the card back after the app restarts.
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

  /// Same as updatePosition, but also returns what the backend worked out:
  /// - etaMinutes / distanceMeters: the ETA patients see, null if none
  /// - arrivedAt: the clinic name if this position counts as arrived
  /// - currentLocation: the clinic the doctor is inside now, or null
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

  /// Saved target lat/lng of each clinic.
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

  /// Saves a clinic's target lat/lng.
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
