import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';

class ScheduleService {
  ScheduleService._();

  /* This asks the backend which time slots are not available on a given
  day for a given clinic. A slot counts as blocked if it already has an
  appointment (any status except cancelled) or if staff manually blocked
  it. This is used while booking, so the app can grey out full slots. */
  static Future<List<String>> getBlockedSlots({
    required String location,
    required String date,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/schedule/get_blocked_slots.php',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'location': location, 'date': date}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load schedule.');
    }

    return List<String>.from(body['blocked_slots'] as List);
  }

  /* This gets more detail than getBlockedSlots above. It tells you
  which slots are blocked with no patient in them, and which slots are
  booked with a real patient (including that patient's name and
  appointment info). This is used by the staff "Manage Time Slots"
  screen, so staff can tell the difference between a slot they blocked
  on purpose and a slot that is full because a patient booked it. */
  static Future<
    ({List<String> blockedSlots, Map<String, Map<String, dynamic>> bookedSlots})
  >
  getSlotDetails({required String location, required String date}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/schedule/get_slot_details.php',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'location': location, 'date': date}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load schedule.');
    }

    final bookedSlots = (body['booked_slots'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as Map<String, dynamic>),
    );

    return (
      blockedSlots: List<String>.from(body['blocked_slots'] as List),
      bookedSlots: bookedSlots,
    );
  }

  /// Returns true if the slot is now blocked, false if it is now open.
  /* This lets staff manually block or unblock a time slot by hand, for
  example if the doctor will be out for that time. Calling it on an
  already blocked slot unblocks it, and calling it again blocks it, like
  a switch. It returns the new state after the change, true meaning it
  is now blocked. */
  static Future<bool> toggleSlot({
    required String location,
    required String date,
    required String timeSlot,
    int? userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/schedule/toggle_slot.php');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'location': location,
        'date': date,
        'time_slot': timeSlot,
        'user_id': userId,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to update slot.');
    }

    return body['is_blocked'] as bool;
  }
}
