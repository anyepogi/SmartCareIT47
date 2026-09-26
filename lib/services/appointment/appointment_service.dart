import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';

class BookingResult {
  const BookingResult({required this.appointmentId, required this.code});

  final int appointmentId;
  final String code;
}

class AppointmentService {
  AppointmentService._();

  /* This creates a new appointment in the database. It sends the patient
  id, clinic location, date, and time slot to the backend. The backend
  checks if the slot is still free before saving it. If isReschedule is
  true, it tells the backend this booking replaces an old appointment
  that was just cancelled, so it can log it correctly. If actorUserId is
  given, it means a staff member (doctor or secretary) is booking this
  for the patient, not the patient booking it themselves. If the booking
  works, it returns the new appointment id and its reference code. If it
  fails (for example the slot got taken first), it throws an error with
  the reason from the backend. */
  static Future<BookingResult> book({
    required int userId,
    required String location,
    required String date,
    required String timeSlot,
    bool isReschedule = false,
    int? actorUserId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/appointment/book.php');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'location': location,
        'date': date,
        'time_slot': timeSlot,
        'is_reschedule': isReschedule,
        'actor_user_id': actorUserId,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to book appointment.');
    }

    return BookingResult(
      appointmentId: body['appointment_id'] as int,
      code: body['appointment_code'] as String,
    );
  }

  /// Returns the patient's nearest upcoming booked appointment, or null if
  /// they don't have one.
  static Future<Map<String, dynamic>?> getUpcoming(int userId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointment/get_upcoming.php',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
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

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
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

    final response = await http.post(uri);

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

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
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

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
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

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
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

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
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
