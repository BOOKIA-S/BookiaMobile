import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs method, path and status in debug builds. Never logs headers (SEG-01).
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({void Function(String)? log}) : _log = log ?? debugPrint;

  final void Function(String) _log;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) _log('--> ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) _log('<-- ${response.statusCode} ${response.realUri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _log(
        '<-- ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.uri}',
      );
    }
    handler.next(err);
  }
}
