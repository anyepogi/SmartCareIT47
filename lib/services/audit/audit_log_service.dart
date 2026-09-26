import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    required this.description,
    required this.createdAt,
  });

  final int id;
  final int? userId;
  final String userName;
  final String role;
  final String action;
  final String resourceType;
  final String? resourceId;
  final String description;
  final String createdAt;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      userName: json['user_name'] as String,
      role: json['role'] as String,
      action: json['action'] as String,
      resourceType: json['resource_type'] as String,
      resourceId: json['resource_id'] as String?,
      description: json['description'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

/// The fixed set of resource types the app ever logs — matches exactly
/// what the backend passes to log_audit() across every endpoint.
const List<String> auditResourceTypes = ['Appointment', 'User', 'Geofence', 'Auth', 'Contact'];

/// The fixed set of roles that can perform a logged action — matches
/// exactly what audit_lookup_user() in the backend can resolve.
const List<String> auditRoles = ['patient', 'doctor', 'secretary', 'guest', 'system'];

class AuditLogService {
  AuditLogService._();

  /* This asks the backend for the list of audit log entries, newest
  first. All the filters are optional. If you leave them empty, it
  returns everything (up to the limit). action filters by type of action
  like CREATE or UPDATE. resourceType filters by what was changed, like
  Appointment or User. role filters by who did it, like doctor or
  patient. search looks for matching text in the description, resource
  id, or the name of the person who did it. startDate and endDate (in
  yyyy-MM-dd format) limit the results to that date range. This is what
  powers the filters on the Audit Logs screen. */
  static Future<List<AuditLogEntry>> getLogs({
    String? action,
    String? resourceType,
    String? role,
    String? search,
    String? startDate,
    String? endDate,
    int limit = 200,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/audit/get_logs.php');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': action,
        'resource_type': resourceType,
        'role': role,
        'search': search,
        'start_date': startDate,
        'end_date': endDate,
        'limit': limit,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load audit logs.');
    }

    return (body['logs'] as List)
        .map((entry) => AuditLogEntry.fromJson(entry as Map<String, dynamic>))
        .toList();
  }
}
