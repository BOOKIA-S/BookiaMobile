import 'dart:convert';
import 'dart:typed_data';

import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? last;
  final requests = <RequestOptions>[];
  int status = 200;
  Object data = {'message': 'fixture'};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    last = options;
    requests.add(options);
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
      expect(
        (container.read(currentSessionProvider) as SignedInSession).name,
        'Ana',
      );
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
      expect(container.read(currentSessionProvider), isA<GuestSession>());
      expect(await container.read(tokenStorageProvider).readToken(), isNull);
    },
  );

  test(
    'failed account switch leaves the active session and token intact',
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
      await controller.login('a@b.mx', 'correct-password');
      adapter.status = 401;

      await controller.login('other@b.mx', 'wrong-password');

      expect(adapter.last!.headers.containsKey('Authorization'), isFalse);
      expect(container.read(currentSessionProvider), isA<SignedInSession>());
      expect(
        await container.read(tokenStorageProvider).readToken(),
        'fixture-token',
      );
      expect(container.read(authControllerProvider).hasError, isTrue);
    },
  );

  testWidgets('splash restores the stored session and profile signs out', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = _Adapter()
      ..data = {
        'user': {'_id': 'u1', 'name': 'Ana', 'role': 'reader'},
      };
    final container = ProviderContainer(
      overrides: [
        ...offlineOverrides(),
        apiBaseUrlProvider.overrideWithValue('https://bookia.test/api'),
        dioProvider.overrideWithValue(Dio()..httpClientAdapter = adapter),
      ],
    );
    addTearDown(container.dispose);
    await container.read(tokenStorageProvider).saveToken('fixture-token');
    final router = createRouter(initialLocation: AppRoutes.splash);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.home);
    expect(
      adapter.requests.any(
        (request) =>
            request.uri.path == '/api/auth/me' &&
            request.headers['Authorization'] == 'Bearer fixture-token',
      ),
      isTrue,
    );
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Sesión iniciada: Ana'), findsOneWidget);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(container.read(currentSessionProvider), isA<GuestSession>());
    expect(await container.read(tokenStorageProvider).readToken(), isNull);
  });
}
