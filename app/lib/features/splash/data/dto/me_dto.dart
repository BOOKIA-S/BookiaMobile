/// Factory (PAT-05) for the body of `GET /auth/me`: `{ user: {...} }`.
class MeDto {
  const MeDto({required this.name, required this.role});

  factory MeDto.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return MeDto(name: user['name'] as String, role: user['role'] as String);
  }

  final String name;
  final String role;
}
