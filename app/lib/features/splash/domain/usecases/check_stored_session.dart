import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/splash/domain/entities/session_status.dart';
import 'package:bookia_mobile/features/splash/domain/repositories/session_repository.dart';

/// Decides how the app opens (SPECS 01): valid token → signed in;
/// 401 → forget the token and open as guest; no token or offline → guest.
class CheckStoredSession {
  const CheckStoredSession(this._repository);

  final SessionRepository _repository;

  Future<SessionStatus> call() async {
    if (!await _repository.hasStoredToken()) return const GuestSession();
    try {
      return await _repository.fetchCurrentUser();
    } on UnauthorizedFailure {
      await _repository.clearStoredToken();
      return const GuestSession();
    } on Failure {
      // Offline or server error: keep the token and try again next start.
      return const GuestSession();
    }
  }
}
