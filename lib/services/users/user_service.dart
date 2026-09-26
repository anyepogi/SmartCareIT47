import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../state/app_session.dart';
import '../api_config.dart';

class UserService {
  UserService._();

  /* This gets the list of every account in the system, no matter their
  role (patient, doctor, or secretary). This is used by the admin User
  Management screen. */
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/get_all_users.php');

    final response = await http.post(uri);

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load users.');
    }

    return List<Map<String, dynamic>>.from(body['users'] as List);
  }

  /* This lets an admin edit someone else's account info, and even
  change their role or reset their password. It only sends a new
  password if one was actually typed in, so leaving the password field
  blank keeps the old password unchanged. It also automatically sends
  the id of whoever is currently logged in as actorUserId, so the
  backend can record in the audit log who made this change. */
  static Future<void> updateUser({
    required int userId,
    required String email,
    required String firstName,
    required String middleName,
    required String lastName,
    required String contactNumber,
    required String gender,
    required String address,
    required String emergencyContact,
    required String role,
    String? password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/update_user.php');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'email': email,
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'contact_number': contactNumber,
        'gender': gender,
        'address': address,
        'emergency_contact': emergencyContact,
        'role': role,
        if (password != null && password.isNotEmpty) 'password': password,
        'actor_user_id': SmartCareSession.currentUserId,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to update user.');
    }
  }

  /* This permanently deletes a user account from the database. It
  automatically records who is currently logged in as the one who did
  the deleting, so it shows up correctly in the audit log. */
  static Future<void> deleteUser(int userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/delete_user.php');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'actor_user_id': SmartCareSession.currentUserId,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to delete user.');
    }
  }
}
