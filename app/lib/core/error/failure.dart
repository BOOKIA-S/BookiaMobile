/// Errors that cross layers (ARQ-05). Never let a DioException leave data/.
sealed class Failure implements Exception {
  const Failure(this.message);

  /// Text safe to show on screen (es-MX).
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// 400: validation error, malformed id or `Invalid isbn`.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// 401: no session, expired token or malformed `Authorization` header.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Inicia sesión para continuar.']);
}

/// 403: the role has no permission.
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'No tienes permiso para esto.']);
}

/// 403 with `code: PASSWORD_CHANGE_REQUIRED`.
final class PasswordChangeRequiredFailure extends Failure {
  const PasswordChangeRequiredFailure([
    super.message = 'Necesitas cambiar tu contraseña.',
  ]);
}

/// 404: the resource does not exist.
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'No encontramos lo que buscas.']);
}

/// 409: not enough copies, state not allowed or duplicate.
final class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

/// 429: too many login attempts.
final class RateLimitFailure extends Failure {
  const RateLimitFailure([
    super.message = 'Demasiados intentos. Espera unos minutos.',
  ]);
}

/// 5xx or an unexpected response.
final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Algo salió mal. Intenta de nuevo más tarde.',
  ]);
}

/// No connection or timeout.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Revisa tu conexión a internet.']);
}
