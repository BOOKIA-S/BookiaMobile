import 'package:bookia_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required String baseUrl,
    required this.tokens,
    this.onUnauthorized,
  }) : _base = Uri.parse(baseUrl),
       _apiPath = Uri.parse(baseUrl).path.replaceAll(RegExp(r'/$'), '');

  final Uri _base;
  final TokenStorage tokens;
  final String _apiPath;
  final void Function()? onUnauthorized;

  bool _isProtected(RequestOptions options) {
    final uri = options.uri;
    if (uri.origin != _base.origin || !uri.path.startsWith('$_apiPath/')) {
      return false;
    }
    final path = uri.path.substring(_apiPath.length);
    return path != '/auth/login' &&
        path != '/auth/register' &&
        path != '/health' &&
        !path.startsWith('/books') &&
        !path.startsWith('/stores');
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (_isProtected(options)) {
        final token = await tokens.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
      handler.next(options);
    } catch (_) {
      handler.reject(
        DioException(
          requestOptions: options,
          message: 'Could not access secure storage',
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      final header = err.requestOptions.headers['Authorization'];
      if (err.response?.statusCode == 401 &&
          _isProtected(err.requestOptions) &&
          header is String &&
          header.startsWith('Bearer ') &&
          await tokens.readToken() == header.substring(7)) {
        await tokens.clearToken();
        onUnauthorized?.call();
      }
    } catch (_) {
      // Preserve the original 401 even if secure storage fails.
    }
    handler.next(err);
  }
}
