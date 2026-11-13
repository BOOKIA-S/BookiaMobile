import 'package:bookia_mobile/core/error/failure.dart';
import 'package:dio/dio.dart';

/// Factory (PAT-05): builds the right [Failure] for a Dio error.
abstract final class FailureFactory {
  static Failure fromDioException(DioException e) {
    if (e.error case final Failure failure) return failure;
    return switch (e.type) {
      DioExceptionType.badResponse => fromResponse(e.response),
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => const NetworkFailure(),
      _ => const ServerFailure(),
    };
  }

  /// Maps the API error body `{ message, code? }` (API_USAGE §6).
  static Failure fromResponse(Response<Object?>? response) {
    final body = response?.data;
    final message = body is Map && body['message'] is String
        ? body['message'] as String
        : null;
    final code = body is Map && body['code'] is String
        ? body['code'] as String
        : null;
    return switch (response?.statusCode) {
      400 => ValidationFailure(message ?? 'Revisa los datos enviados.'),
      401 => const UnauthorizedFailure(),
      403 when code == 'PASSWORD_CHANGE_REQUIRED' =>
        const PasswordChangeRequiredFailure(),
      403 => const ForbiddenFailure(),
      404 => const NotFoundFailure(),
      409 => ConflictFailure(message ?? 'La operación no está permitida.'),
      429 => const RateLimitFailure(),
      _ => const ServerFailure(),
    };
  }
}
