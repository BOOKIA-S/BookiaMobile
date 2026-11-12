import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/error/failure_factory.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Failure _map(int status, [Map<String, Object?>? body]) {
  final options = RequestOptions(path: '/x');
  return FailureFactory.fromDioException(
    DioException.badResponse(
      statusCode: status,
      requestOptions: options,
      response: Response<Object?>(
        requestOptions: options,
        statusCode: status,
        data: body,
      ),
    ),
  );
}

void main() {
  test('maps each API status to its Failure (API_USAGE §6)', () {
    expect(_map(400, {'message': 'Invalid isbn'}), isA<ValidationFailure>());
    expect(_map(400, {'message': 'Invalid isbn'}).message, 'Invalid isbn');
    expect(_map(401), isA<UnauthorizedFailure>());
    expect(_map(403), isA<ForbiddenFailure>());
    expect(
      _map(403, {'message': 'x', 'code': 'PASSWORD_CHANGE_REQUIRED'}),
      isA<PasswordChangeRequiredFailure>(),
    );
    expect(_map(404), isA<NotFoundFailure>());
    expect(_map(409), isA<ConflictFailure>());
    expect(_map(429), isA<RateLimitFailure>());
    expect(_map(500), isA<ServerFailure>());
  });

  test('timeouts become NetworkFailure', () {
    final e = DioException.connectionTimeout(
      timeout: const Duration(seconds: 1),
      requestOptions: RequestOptions(path: '/x'),
    );
    expect(FailureFactory.fromDioException(e), isA<NetworkFailure>());
  });

  test('keeps a Failure already attached by ErrorInterceptor', () {
    final e = DioException(
      requestOptions: RequestOptions(path: '/x'),
      error: const NotFoundFailure(),
    );
    expect(FailureFactory.fromDioException(e), isA<NotFoundFailure>());
  });
}
