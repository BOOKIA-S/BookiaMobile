/// Result of checking the stored session when the app starts (screen 01).
sealed class SessionStatus {
  const SessionStatus();
}

/// No token, an expired token or no connection: the app opens as a visitor.
final class GuestSession extends SessionStatus {
  const GuestSession();
}

/// The stored token is valid; the fields come from `GET /auth/me`.
///
/// [id], [email], [storeId], [mustChangePassword] and [createdAt] are optional
/// so older call sites that only know the name and role keep working. The
/// profile screen refreshes them from the API when it opens.
final class SignedInSession extends SessionStatus {
  const SignedInSession({
    this.id = '',
    this.email = '',
    required this.name,
    required this.role,
    this.storeId,
    this.mustChangePassword = false,
    this.createdAt,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String? storeId;
  final bool mustChangePassword;
  final DateTime? createdAt;

  SignedInSession copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? storeId,
    bool? mustChangePassword,
    DateTime? createdAt,
  }) => SignedInSession(
    id: id ?? this.id,
    email: email ?? this.email,
    name: name ?? this.name,
    role: role ?? this.role,
    storeId: storeId ?? this.storeId,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    createdAt: createdAt ?? this.createdAt,
  );
}
