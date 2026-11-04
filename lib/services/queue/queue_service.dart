import 'dart:convert';

import '../api_config.dart';

class QueueService {
  QueueService._();

  /* This gets the list of patients in the queue for a day, sorted by
  time slot. It includes appointments that are booked, sent to the
  doctor, currently being served, or already completed. You can filter
  by clinic location, and if you do not give a date it just uses today. */
  static Future<List<Map<String, dynamic>>> getTodayQueue({
    String? location,
    String? date,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointment/get_today_queue.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({'location': location, 'date': date}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load queue.');
    }

    return List<Map<String, dynamic>>.from(body['queue'] as List);
  }

  /* This is the first step of the queue workflow. The secretary uses
  this to move a patient's appointment from "booked" to "sent to
  doctor", meaning the patient checked in and is now waiting for the
  doctor to see them. */
  static Future<void> sendToDoctor(int appointmentId) async {
    await _post('send_to_doctor.php', {'appointment_id': appointmentId});
  }

  /* This is the second step of the queue workflow. The doctor uses this
  to confirm they are now seeing the patient, which changes the status
  from "sent to doctor" to "serving". */
  static Future<void> confirmReceived(int appointmentId) async {
    await _post('confirm_received.php', {'appointment_id': appointmentId});
  }

  /* This is used when a patient in the queue never showed up. It moves
  the appointment to "no show", taking it out of the waiting line but
  keeping it in the records. Only works while the patient is still
  waiting or was just called in, not once they are with the doctor. */
  static Future<void> markNoShow(int appointmentId) async {
    await _post('mark_no_show.php', {'appointment_id': appointmentId});
  }

  /* This is the last step of the queue workflow. The doctor uses this
  to mark the consultation as finished. If the doctor also wants the
  patient to come back for a follow up visit, they can pass a follow up
  date and clinic (the clinic can be different from where this visit
  happened, same as a normal booking). When a follow up is given, this
  does not just write a note, it actually creates a real new appointment
  for that follow up date, with the next queue number there (returned as
  followUpQueueCode, like SO4), so it shows up everywhere normal
  appointments do. If marking complete works but the follow up booking
  itself fails (for example the clinic is closed that day), this still
  finishes the visit and returns a warning message instead of throwing
  an error, so the doctor knows to book the follow up by hand. */
  static Future<({String? warning, String? followUpQueueCode})>
  completeAppointment(
    int appointmentId, {
    String? followUpDate,
    String? followUpLocation,
    int? actorUserId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointment/complete_appointment.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({
        'appointment_id': appointmentId,
        'follow_up_date': followUpDate,
        'follow_up_location': followUpLocation,
        'actor_user_id': actorUserId,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Request failed.');
    }

    return (
      warning: body['follow_up_warning'] as String?,
      followUpQueueCode: body['follow_up_queue_code'] as String?,
    );
  }

  /// Returns the appointment currently being served at a location, if any.
  static Future<Map<String, dynamic>?> getNowServing(String location) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointment/get_now_serving.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({'location': location}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load now-serving info.');
    }

    return body['now_serving'] as Map<String, dynamic>?;
  }

  static Future<void> _post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/appointment/$endpoint');

    final response = await ApiConfig.post(uri, body: jsonEncode(body));

    final Map<String, dynamic> decoded = jsonDecode(response.body);
    if (response.statusCode != 200 || decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Request failed.');
    }
  }
}
