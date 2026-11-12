import 'dart:convert';
import 'dart:typed_data';

import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with [status] and [body], and records the request.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body, {this.fail = false});

  final int status;
  final Object body;
  final bool fail;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    if (fail) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
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

ApiClient _client(_FakeAdapter adapter) => ApiClient(
  baseUrl: 'http://api.test/api',
  dio: Dio()..httpClientAdapter = adapter,
);

void main() {
  test('get returns the decoded body and skips empty query values', () async {
    final adapter = _FakeAdapter(200, {'status': 'ok'});
    final body = await _client(adapter)
        .get<Map<String, dynamic>>('/health', query: {'q': 'x', 'genre': ''});

    expect(body['status'], 'ok');
    expect(adapter.last!.uri.toString(), 'http://api.test/api/health?q=x');
  });

  test('an HTTP error is thrown as the matching Failure', () async {
    final adapter = _FakeAdapter(409, {'message': 'Sin copias'});
    expect(
      () => _client(adapter).post<Object?>('/reservations'),
      throwsA(
        isA<ConflictFailure>().having(
          (f) => f.message,
          'message',
          'Sin copias',
        ),
      ),
    );
  });

  test('a connection error is thrown as NetworkFailure', () async {
    final adapter = _FakeAdapter(200, {}, fail: true);
    expect(
      () => _client(adapter).get<Object?>('/books'),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('a body of the wrong type is thrown as ServerFailure', () async {
    final adapter = _FakeAdapter(200, ['not', 'a', 'map']);
    expect(
      () => _client(adapter).get<Map<String, dynamic>>('/books'),
      throwsA(isA<ServerFailure>()),
    );
  });
}
