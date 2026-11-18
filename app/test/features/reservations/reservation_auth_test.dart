import 'dart:convert';
import 'dart:typed_data';

import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/core/storage/token_storage.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter_test/flutter_test.dart';

import '../../helpers/failing_secure_storage.dart';

final _created = {
  '_id': 'r1',
  'user_id': 'u1',
  'offer_id': 'o1',
  'store_id': 's1',
  'book_id': 'b1',
  'price': 129,
  'quantity': 1,
  'status': 'pendiente',
  'expires_at': '2026-11-19T20:00:00.000Z',
};

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 201;
  Object body = _created;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _TimeoutAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) {
    calls++;
    throw DioException.connectionTimeout(
      timeout: const Duration(seconds: 1),
      requestOptions: options,
    );
  }

  @override
  void close({bool force = false}) {}
}

ProviderContainer _container({
  required HttpClientAdapter adapter,
  TokenStorage? tokens,
}) {
  final container = ProviderContainer(
    overrides: [
      apiBaseUrlProvider.overrideWithValue('https://bookia.test/api'),
      dioProvider.overrideWithValue(Dio()..httpClientAdapter = adapter),
      if (tokens != null) tokenStorageProvider.overrideWithValue(tokens),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('POST /reservations carries the Bearer token', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = _Adapter();
    final container = _container(adapter: adapter);
    await container.read(tokenStorageProvider).saveToken('fixture-token');

    await container
        .read(reservationRepositoryProvider)
        .create(offerId: 'o1', quantity: 1);

    expect(adapter.requests.single.uri.path, '/api/reservations');
    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer fixture-token',
    );
  });

  test('a 401 clears the expired session and token', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = _Adapter()
      ..status = 401
      ..body = {'message': 'Invalid session'};
    final container = _container(adapter: adapter);
    await container.read(tokenStorageProvider).saveToken('old-token');
    container
        .read(currentSessionProvider.notifier)
        .set(const SignedInSession(name: 'Ana', role: 'reader'));

    await expectLater(
      container
          .read(reservationRepositoryProvider)
          .create(offerId: 'o1', quantity: 1),
      throwsA(isA<UnauthorizedFailure>()),
    );

    expect(container.read(currentSessionProvider), isA<GuestSession>());
    expect(await container.read(tokenStorageProvider).readToken(), isNull);
  });

  test('a timeout becomes NetworkFailure, never a DioException', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = _TimeoutAdapter();
    final container = _container(adapter: adapter);

    await expectLater(
      container
          .read(reservationRepositoryProvider)
          .create(offerId: 'o1', quantity: 1),
      throwsA(isA<NetworkFailure>()),
    );
    expect(adapter.calls, 1);
  });

  test(
    'a secure-storage read failure sends no request and stays a Failure',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final adapter = _Adapter();
      final container = _container(
        adapter: adapter,
        tokens: const TokenStorage(storage: FailingSecureStorage('read')),
      );

      await expectLater(
        container
            .read(reservationRepositoryProvider)
            .create(offerId: 'o1', quantity: 1),
        throwsA(isA<Failure>()),
      );
      expect(adapter.requests, isEmpty);
    },
  );
}
