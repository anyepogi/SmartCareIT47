import 'dart:convert';

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

/// Resource types the backend logs. Must match the log_audit() calls.
const List<String> auditResourceTypes = [
  'Appointment',
  'User',
  'Geofence',
  'Auth',
  'Contact',
];

/// Roles that can show up in the logs. Must match audit_lookup_user().
const List<String> auditRoles = [
  'patient',
  'doctor',
  'secretary',
  'guest',
  'system',
];

class AuditLogService {
  AuditLogService._();

  /// Audit log entries, newest first. All filters are optional:
  /// action (CREATE, UPDATE...), resourceType (Appointment, User...), role,
  /// search (description, resource id, or name), and startDate/endDate in
  /// yyyy-MM-dd.
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

    final response = await ApiConfig.post(
      uri,
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
