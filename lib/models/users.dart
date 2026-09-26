class UserModel {
  final int? userId;
  final String email;
  final String password;
  final String role;
  final DateTime? createdAt;

  UserModel({
    this.userId,
    required this.email,
    required this.password,
    required this.role,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'],
      email: json['email'],
      password: json['password'] ?? '',
      role: json['role'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'password': password,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}