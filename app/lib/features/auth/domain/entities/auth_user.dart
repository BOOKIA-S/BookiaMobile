class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.storeId,
    required this.mustChangePassword,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String? storeId;
  final bool mustChangePassword;
  final DateTime createdAt;
}
