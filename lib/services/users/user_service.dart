import 'dart:convert';

import '../../state/app_session.dart';
import '../api_config.dart';

class UserService {
  UserService._();

  /// All accounts (patients, doctors, secretaries). Used by User Management.
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/get_all_users.php');

    final response = await ApiConfig.post(uri);

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load users.');
    }

    return List<Map<String, dynamic>>.from(body['users'] as List);
  }

  /// Admin edit of another account, including role and password. The
  /// password is only sent if one was typed. The logged in user is sent as
  /// actorUserId for the audit log.
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

    final response = await ApiConfig.post(
      uri,
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

  /// Deletes an account for good. The logged in user is recorded in the
  /// audit log.
  static Future<void> deleteUser(int userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/delete_user.php');

    final response = await ApiConfig.post(
      uri,
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
