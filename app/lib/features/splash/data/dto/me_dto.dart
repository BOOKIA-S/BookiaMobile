/// Factory (PAT-05) for the body of `GET /auth/me`: `{ user: {...} }`.
class MeDto {
  const MeDto({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.storeId,
    required this.mustChangePassword,
    required this.createdAt,
  });

  factory MeDto.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return MeDto(
      id: user['_id'] as String? ?? '',
      email: user['email'] as String? ?? '',
      name: user['name'] as String,
      role: user['role'] as String,
      storeId: user['store_id'] as String?,
      mustChangePassword: user['must_change_password'] == true,
      createdAt: DateTime.tryParse(user['created_at'] as String? ?? ''),
    );
  }

  final String id;
  final String email;
  final String name;
  final String role;
  final String? storeId;
  final bool mustChangePassword;
  final DateTime? createdAt;
}
