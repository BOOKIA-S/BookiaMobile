import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/error/failure_factory.dart';
import 'package:bookia_mobile/core/network/interceptors/error_interceptor.dart';
import 'package:bookia_mobile/core/network/interceptors/logging_interceptor.dart';
import 'package:dio/dio.dart';

/// Only door to the BOOKIA API (SRV-03). Throws [Failure], never Dio errors.
///
/// Chain of Responsibility (PAT-08): [extraInterceptors] (for example the
/// AuthInterceptor) run first, then logging, then error mapping.
class ApiClient {
  ApiClient({
    required String baseUrl,
    List<Interceptor> extraInterceptors = const [],
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = baseUrl
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 15)
      ..responseType = ResponseType.json;
    _dio.interceptors.addAll([
      ...extraInterceptors,
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  final Dio _dio;

  Future<T> get<T>(String path, {Map<String, Object?>? query}) =>
      _send(() => _dio.get<T>(path, queryParameters: _clean(query)));

  Future<T> post<T>(String path, {Object? body}) =>
      _send(() => _dio.post<T>(path, data: body));

  Future<T> put<T>(String path, {Object? body}) =>
      _send(() => _dio.put<T>(path, data: body));

  Future<T> patch<T>(String path, {Object? body}) =>
      _send(() => _dio.patch<T>(path, data: body));

  Future<T> delete<T>(String path) => _send(() => _dio.delete<T>(path));

  Future<T> _send<T>(Future<Response<T>> Function() call) async {
    try {
      return (await call()).data as T;
    } on DioException catch (e) {
      throw FailureFactory.fromDioException(e);
    } on TypeError {
      throw const ServerFailure();
    }
  }

  /// Drops null and empty values so optional filters are not sent.
  static Map<String, Object?>? _clean(Map<String, Object?>? query) =>
      query == null
      ? null
      : {
          for (final e in query.entries)
            if (e.value != null && e.value != '') e.key: e.value,
        };
}
