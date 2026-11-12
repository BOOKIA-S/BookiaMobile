import 'package:bookia_mobile/core/error/failure_factory.dart';
import 'package:dio/dio.dart';

/// Last link of the chain (PAT-08): attaches a Failure to every Dio error.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: FailureFactory.fromDioException(err)));
  }
}
