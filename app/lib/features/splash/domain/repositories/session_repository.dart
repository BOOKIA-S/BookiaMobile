import 'package:bookia_mobile/features/splash/domain/entities/session_status.dart';

/// Stored session access for the splash screen. Implemented in data/ (PAT-01).
abstract interface class SessionRepository {
  /// Whether a token was saved by a previous login.
  Future<bool> hasStoredToken();

  /// `GET /auth/me` with the stored token. Throws a Failure on error.
  Future<SignedInSession> fetchCurrentUser();

  /// Forgets the stored token (used after a 401).
  Future<void> clearStoredToken();
}
