/// Result of checking the stored session when the app starts (screen 01).
sealed class SessionStatus {
  const SessionStatus();
}

/// No token, an expired token or no connection: the app opens as a visitor.
final class GuestSession extends SessionStatus {
  const GuestSession();
}

/// The stored token is valid; [name] and [role] come from `GET /auth/me`.
final class SignedInSession extends SessionStatus {
  const SignedInSession({required this.name, required this.role});

  final String name;
  final String role;
}
