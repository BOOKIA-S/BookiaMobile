import 'dart:convert';
import 'dart:typed_data';

import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? last;
  int status = 200;
  Object data = {'message': 'fixture'};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(data),
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

  test('the shared ApiClient uses secure storage for Bearer and keeps it on login 401', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = _Adapter();
    final container = ProviderContainer(
      overrides: [
        apiBaseUrlProvider.overrideWithValue('https://bookia.test/api'),
        dioProvider.overrideWithValue(Dio()..httpClientAdapter = adapter),
      ],
    );
    addTearDown(container.dispose);
    final tokens = container.read(tokenStorageProvider);
    final client = container.read(apiClientProvider);

    await client.get<Map<String, dynamic>>('/auth/me');
    expect(adapter.last!.headers.containsKey('Authorization'), isFalse);

    await tokens.saveToken('fixture-token');
    await client.get<Map<String, dynamic>>('/auth/me');
    expect(adapter.last!.headers['Authorization'], 'Bearer fixture-token');
    await client.get<Map<String, dynamic>>('/books');
    expect(adapter.last!.headers.containsKey('Authorization'), isFalse);

    adapter.status = 401;
    await expectLater(
      client.post<Map<String, dynamic>>(
        '/auth/login',
        body: {'client': 'mobile'},
      ),
      throwsA(isA<UnauthorizedFailure>()),
    );
    expect(adapter.last!.headers.containsKey('Authorization'), isFalse);
    expect(await tokens.readToken(), 'fixture-token');

    await expectLater(
      client.get<Map<String, dynamic>>('/auth/me'),
      throwsA(isA<UnauthorizedFailure>()),
    );
    expect(adapter.last!.headers['Authorization'], 'Bearer fixture-token');
    expect(await tokens.readToken(), isNull);
  });

  test(
    'a protected 401 expires the shared session after a successful login',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final adapter = _Adapter()
        ..data = {
          'user': {
            '_id': 'u1',
            'email': 'a@b.mx',
            'name': 'Ana',
            'role': 'reader',
            'store_id': null,
            'must_change_password': false,
            'created_at': '2026-11-09T12:00:00Z',
          },
          'token': 'fixture-token',
          'expires_in': 60,
        };
      final container = ProviderContainer(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('https://bookia.test/api'),
          dioProvider.overrideWithValue(Dio()..httpClientAdapter = adapter),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(authControllerProvider.notifier);
      await controller.login('a@b.mx', 'fixture-password');
      expect(controller.currentSession?.user.id, 'u1');
      expect(
        await container.read(tokenStorageProvider).readToken(),
        'fixture-token',
      );
      adapter.status = 401;
      await expectLater(
        container.read(apiClientProvider).get<Map<String, dynamic>>('/auth/me'),
        throwsA(isA<UnauthorizedFailure>()),
      );
      expect(adapter.last!.headers['Authorization'], 'Bearer fixture-token');
      expect(controller.currentSession, isNull);
      expect(await container.read(tokenStorageProvider).readToken(), isNull);
    },
  );
}
