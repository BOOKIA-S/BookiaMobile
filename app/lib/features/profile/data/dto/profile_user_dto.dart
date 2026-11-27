/// Factory (PAT-05) for the `user` object of `/auth/me`.
class ProfileUserDto {
  const ProfileUserDto({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.storeId,
    required this.mustChangePassword,
    required this.createdAt,
  });

  factory ProfileUserDto.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Invalid profile response');
    }
    final id = user['_id'];
    final email = user['email'];
    final name = user['name'];
    final role = user['role'];
    if (id is! String ||
        email is! String ||
        name is! String ||
        role is! String) {
      throw const FormatException('Invalid profile user');
    }
    return ProfileUserDto(
      id: id,
      email: email,
      name: name,
      role: role,
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
