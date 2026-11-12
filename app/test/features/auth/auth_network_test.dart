import 'dart:convert';
import 'dart:typed_data';

import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/features/auth/presentation/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? last;
  int status = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(
        status == 200
            ? {
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
              }
            : {'message': 'fixture'},
      ),
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
  test('the provided repository sends mobile login, staff and register via ApiClient', () async {
    final adapter = _Adapter();
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(
          ApiClient(
            baseUrl: 'https://bookia.test/api',
            dio: Dio()..httpClientAdapter = adapter,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final repository = container.read(authRepositoryProvider);

    final session = await repository.login('a@b.mx', 'fixture-password');
    expect(session.user.id, 'u1');
    expect(session.expiresInSeconds, 60);
    expect(adapter.last!.uri.path, '/api/auth/login');
    expect(adapter.last!.data, {
      'email': 'a@b.mx',
      'password': 'fixture-password',
      'client': 'mobile',
    });

    await repository.login('a@b.mx', 'fixture-password', staff: true);
    expect((adapter.last!.data as Map<String, dynamic>)['portal'], 'admin');
    await repository.register('Ana', 'a@b.mx', 'fixture-password');
    expect(adapter.last!.uri.path, '/api/auth/register');
    expect(adapter.last!.data, {
      'name': 'Ana',
      'email': 'a@b.mx',
      'password': 'fixture-password',
      'client': 'mobile',
    });
  });

  test('HTTP 401, 409 and 429 cross the repository as Failure', () async {
    final adapter = _Adapter();
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(
          ApiClient(
            baseUrl: 'https://bookia.test/api',
            dio: Dio()..httpClientAdapter = adapter,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final repository = container.read(authRepositoryProvider);
    for (final (status, matcher) in [
      (401, isA<UnauthorizedFailure>()),
      (409, isA<ConflictFailure>()),
      (429, isA<RateLimitFailure>()),
    ]) {
      adapter.status = status;
      await expectLater(
        repository.login('a@b.mx', 'fixture-password'),
        throwsA(matcher),
      );
    }
  });
}
