import 'dart:convert';
import 'dart:typed_data';

import 'package:bookia_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:bookia_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? last;
  int status = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode({'message': 'Invalid session'}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'sends bearer only to protected Bookia endpoints and removes expired token',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const tokens = TokenStorage();
      await tokens.saveToken('secret');
      final adapter = _Adapter();
      var expired = false;
      final dio = Dio(BaseOptions(baseUrl: 'https://bookia.test/api'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(
            baseUrl: 'https://bookia.test/api',
            tokens: tokens,
            onUnauthorized: () => expired = true,
          ),
        );
      await dio.get<Object?>('/books');
      expect(adapter.last!.headers.containsKey('Authorization'), isFalse);
      await dio.post<Object?>('/auth/login');
      expect(adapter.last!.headers.containsKey('Authorization'), isFalse);
      await dio.get<Object?>('https://external.test/api/reservations');
      expect(adapter.last!.headers.containsKey('Authorization'), isFalse);
      await dio.get<Object?>('/reservations/mine');
      expect(adapter.last!.headers['Authorization'], 'Bearer secret');
      adapter.status = 401;
      await expectLater(
        dio.get<Object?>('/auth/me'),
        throwsA(isA<DioException>()),
      );
      expect(await tokens.readToken(), isNull);
      expect(expired, isTrue);
    },
  );

  test(
    'login 401 keeps an existing session; missing token sends no bearer',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const tokens = TokenStorage();
      await tokens.saveToken('fixture-token');
      final adapter = _Adapter()..status = 401;
      var expired = false;
      final dio = Dio(BaseOptions(baseUrl: 'https://bookia.test/api'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(
            baseUrl: 'https://bookia.test/api',
            tokens: tokens,
            onUnauthorized: () => expired = true,
          ),
        );

      await expectLater(
        dio.post<Object?>('/auth/login'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.last!.headers.containsKey('Authorization'), isFalse);
      expect(await tokens.readToken(), 'fixture-token');
      expect(expired, isFalse);

      await tokens.clearToken();
      adapter.status = 200;
      await dio.get<Object?>('/auth/me');
      expect(adapter.last!.headers.containsKey('Authorization'), isFalse);
    },
  );
}
