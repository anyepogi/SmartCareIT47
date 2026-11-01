import 'dart:convert';

import '../api_config.dart';

class ProfileService {
  ProfileService._();

  /// A user's personal info. Works for any role.
  static Future<Map<String, dynamic>> getProfile(int userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/profile/get_profile.php');

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({'user_id': userId}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load profile.');
    }

    return body['profile'] as Map<String, dynamic>;
  }

  /// Saves the user's personal info. All fields are sent every time and
  /// replace the old values. Returns the updated profile.
  static Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String firstName,
    required String middleName,
    required String lastName,
    required String dateOfBirth,
    required String contactNumber,
    required String gender,
    required String occupation,
    required String civilStatus,
    required String emergencyContact,
    required String address,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/profile/update_profile.php',
    );

    final response = await ApiConfig.post(
      uri,
      body: jsonEncode({
        'user_id': userId,
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'date_of_birth': dateOfBirth,
        'contact_number': contactNumber,
        'gender': gender,
        'occupation': occupation,
        'civil_status': civilStatus,
        'emergency_contact': emergencyContact,
        'address': address,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to update profile.');
    }

    return body['profile'] as Map<String, dynamic>;
  }
}
