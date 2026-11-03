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

  /// Reference number, e.g. STR2026103003.
  final String code;
  final int queueNumber;

  /// Queue number shown to users, e.g. SO3 or SW3.
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

  /// Books an online appointment and returns the queue number for that
  /// clinic and date (e.g. SO3). To reschedule, pass
  /// rescheduleAppointmentId; the old one is only cancelled after the new
  /// booking goes through. Staff can book for a patient by passing userId.
  /// Throws the backend's message if the booking isn't allowed.
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

  /// Slots left in a clinic session (max 25 per clinic per day, online and
  /// walk-in together). When rescheduling, pass excludeAppointmentId so the
  /// patient's own appointment isn't counted.
  static Future<({int capacity, int used, int remaining})> getSessionSlots({
    required String location,
    required String date,
    int? excludeAppointmentId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointment/get_session_slots.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({
        'location': location,
        'date': date,
        'exclude_appointment_id': excludeAppointmentId,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load session slots.');
    }

    return (
      capacity: body['capacity'] as int,
      used: body['used'] as int,
      remaining: body['remaining'] as int,
    );
  }

  /// Adds a walk-in patient (secretary only). Walk-ins share the queue with
  /// online bookings and show as SW + number. contactNumber is required,
  /// middleName and email are optional.
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

  /// The patient's nearest upcoming appointment, or null if none.
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

  /// Completed visits, newest first. Pass userId for one patient's history,
  /// or leave it out to get everyone's (staff view).
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

  /// Every appointment of every patient, newest first.
  /// Used by Appointment Management.
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

  /// The patient's upcoming appointments, soonest first.
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

  /// The patient's usual days, clinics, and times, ranked by how often
  /// they booked them.
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

  /// Manual status change by staff. actorUserId is sent so it shows up in
  /// the audit log.
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

  /// Cancels an appointment. Only the status changes, the record is kept.
  /// reason is optional. actorUserId is whoever cancelled it (the patient
  /// or staff).
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
