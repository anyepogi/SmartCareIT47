import 'dart:convert';

import '../api_config.dart';

class BookingResult {
  const BookingResult({
    required this.appointmentId,
    required this.code,
    required this.queueNumber,
    required this.queueCode,
  });

  final int appointmentId;

  /// The reference number, like STR2026103003.
  final String code;
  final int queueNumber;

  /// The queue number as shown to people, like SO3 or SW3.
  final String queueCode;

  factory BookingResult.fromJson(Map<String, dynamic> body) => BookingResult(
    appointmentId: body['appointment_id'] as int,
    code: body['appointment_code'] as String,
    queueNumber: body['queue_number'] as int,
    queueCode: body['queue_code'] as String,
  );
}

class AppointmentService {
  AppointmentService._();

  /* This books an online appointment. There are no time slots anymore:
  it sends the patient id, clinic location, and date, and the backend
  gives the patient the next queue number for that clinic's session that
  day (like SO3, the 3rd to book at Sta. Rita). To reschedule, pass
  rescheduleAppointmentId: the backend books the new one first and only
  then cancels the old one, so the patient never loses their appointment
  if the new booking fails. A staff member can book for a patient by
  passing that patient's userId. Throws with the backend's reason if the
  booking is not allowed (for example the clinic is closed that day). */
  static Future<BookingResult> book({
    required int userId,
    required String location,
    required String date,
    int? rescheduleAppointmentId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/appointment/book.php');

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({
        'user_id': userId,
        'location': location,
        'date': date,
        'reschedule_appointment_id': rescheduleAppointmentId,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to book appointment.');
    }

    return BookingResult.fromJson(body);
  }

  /* This records a walk-in patient (secretary only): someone who came to
  the clinic without booking in the app and may not have an account. The
  walk-in gets the next queue number for that clinic and date, shared
  with online bookings, shown like SW4. middleName and email are
  optional; contactNumber is required. */
  static Future<BookingResult> bookWalkIn({
    required String lastName,
    required String firstName,
    String? middleName,
    required String contactNumber,
    String? email,
    required String location,
    required String date,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointment/book_walkin.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({
        'last_name': lastName,
        'first_name': firstName,
        'middle_name': middleName ?? '',
        'contact_number': contactNumber,
        'email': email ?? '',
        'location': location,
        'date': date,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to record the walk-in.');
    }

    return BookingResult.fromJson(body);
  }

  /// Returns the patient's nearest upcoming booked appointment, or null if
  /// they don't have one.
  static Future<Map<String, dynamic>?> getUpcoming(int userId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointment/get_upcoming.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({'user_id': userId}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load appointment.');
    }

    return body['appointment'] as Map<String, dynamic>?;
  }

  /// Returns completed visits, newest first. Pass [userId] to scope to one
  /// patient (for their own visit history), or omit it for every patient's
  /// completed visits (for staff review).
  static Future<List<Map<String, dynamic>>> getVisitHistory({
    int? userId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointment/get_visit_history.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({'user_id': userId}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load visit history.');
    }

    return List<Map<String, dynamic>>.from(body['visits'] as List);
  }

  /// Returns every appointment in the system (any patient, any status),
  /// newest first. Used by the staff-facing Appointment Management screen.
  static Future<List<Map<String, dynamic>>> getAllAppointments() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointment/get_all_appointments.php',
    );

    final response = await ApiConfig.post(uri);

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load appointments.');
    }

    return List<Map<String, dynamic>>.from(body['appointments'] as List);
  }

  /// Returns all of the patient's upcoming (booked, not-yet-passed)
  /// appointments, ordered soonest first.
  static Future<List<Map<String, dynamic>>> getAllUpcoming(int userId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointment/get_all_upcoming.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({'user_id': userId}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load appointments.');
    }

    return List<Map<String, dynamic>>.from(body['appointments'] as List);
  }

  /// Returns the patient's historical booking pattern: weekdays, locations,
  /// and time slots ranked from most to least frequently booked.
  static Future<Map<String, dynamic>> getBookingPattern(int userId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointment/get_booking_pattern.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({'user_id': userId}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load booking pattern.');
    }

    return body;
  }

  /* This lets a doctor or secretary change an appointment's status by
  hand, for example from Pending to Confirmed. It sends the appointment
  id, the new status, and who made the change (actorUserId) to the
  backend, so the change gets written to the audit log too. */
  static Future<void> updateStatus({
    required int appointmentId,
    required String status,
    int? actorUserId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointment/update_status.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({
        'appointment_id': appointmentId,
        'status': status,
        'actor_user_id': actorUserId,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to update status.');
    }
  }

  /* This cancels an appointment. It does not delete the row from the
  database, it only changes its status to cancelled, so the record is
  still kept for history. The reason is optional text explaining why it
  was cancelled (for example "Rescheduled by the clinic"), and
  actorUserId records who cancelled it, since it might be the patient
  themselves or a staff member cancelling on their behalf. */
  static Future<void> cancel(
    int appointmentId, {
    int? actorUserId,
    String? reason,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/appointment/cancel.php');

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({
        'appointment_id': appointmentId,
        'actor_user_id': actorUserId,
        'reason': reason,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to cancel appointment.');
    }
  }
}
