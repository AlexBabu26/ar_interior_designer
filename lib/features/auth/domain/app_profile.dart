enum AppProfileRole {
  customer('customer'),
  admin('admin'),
  carpenter('carpenter');

  const AppProfileRole(this.value);

  final String value;

  static AppProfileRole fromValue(String value) {
    return AppProfileRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => throw FormatException('Unsupported profile role: $value'),
    );
  }
}

class AppProfile {
  const AppProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final AppProfileRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAdmin => role == AppProfileRole.admin;
  bool get isCarpenter => role == AppProfileRole.carpenter;

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    return AppProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      role: AppProfileRole.fromValue(json['role'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'role': role.value,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
