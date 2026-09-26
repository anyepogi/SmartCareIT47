import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';

class ProfileService {
  ProfileService._();

  /* This asks the backend for a user's personal info, like their name,
  birthday, address, and so on, using their user id. This works the
  same for patients, doctors, and secretaries. */
  static Future<Map<String, dynamic>> getProfile(int userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/profile/get_profile.php');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load profile.');
    }

    return body['profile'] as Map<String, dynamic>;
  }

  /* This saves changes to a user's personal info back to the database.
  All the fields are sent together every time, even the ones that did
  not change, and the backend just overwrites the old values with these
  new ones. It sends back the updated profile so the screen can refresh
  and show the saved info right away. */
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

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
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
