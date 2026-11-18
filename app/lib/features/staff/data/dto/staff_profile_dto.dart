/// Body of `GET /auth/me`: `{ user: { name, role, store_id, ... } }`.
class StaffProfileDto {
  const StaffProfileDto({
    required this.name,
    required this.role,
    required this.mustChangePassword,
    this.storeId,
  });

  /// Factory (PAT-05). Throws [FormatException] without a usable `user`.
  factory StaffProfileDto.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Invalid profile');
    }
    final name = user['name'];
    final role = user['role'];
    if (name is! String || role is! String || role.isEmpty) {
      throw const FormatException('Invalid profile');
    }
    final storeId = user['store_id'];
    return StaffProfileDto(
      name: name,
      role: role,
      storeId: storeId is String && storeId.isNotEmpty ? storeId : null,
      mustChangePassword: user['must_change_password'] == true,
    );
  }

  final String name;
  final String role;
  final String? storeId;
  final bool mustChangePassword;
}
