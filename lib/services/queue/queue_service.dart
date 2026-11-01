import 'dart:convert';

import '../api_config.dart';

class QueueService {
  QueueService._();

  /// The queue for a day: booked, sent to doctor, serving, and completed.
  /// location is optional; date defaults to today.
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

  /// Step 1 (secretary): the patient checked in, booked -> sent_to_doctor.
  static Future<void> sendToDoctor(int appointmentId) async {
    await _post('send_to_doctor.php', {'appointment_id': appointmentId});
  }

  /// Step 2 (doctor): the doctor is now seeing the patient -> serving.
  static Future<void> confirmReceived(int appointmentId) async {
    await _post('confirm_received.php', {'appointment_id': appointmentId});
  }

  /// Marks a patient who didn't show up as no_show. Only while they're
  /// still waiting or just called in, not once they're with the doctor.
  static Future<void> markNoShow(int appointmentId) async {
    await _post('mark_no_show.php', {'appointment_id': appointmentId});
  }

  /// Last step (doctor): marks the visit completed. If a follow-up date and
  /// clinic are given, a real appointment is booked for it and its queue
  /// number comes back as followUpQueueCode. If that booking fails, the
  /// visit is still completed and warning says why, so the doctor can book
  /// the follow-up by hand.
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
