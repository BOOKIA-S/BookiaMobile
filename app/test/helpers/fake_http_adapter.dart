import 'dart:convert';
import 'dart:typed_data';

import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:dio/dio.dart';

/// Answers every request with [status] and [body] and records the last one,
/// so data tests run the real ApiClient without a network.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.status, this.body);

  final int status;
  final Object body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
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

ApiClient fakeApiClient(FakeHttpAdapter adapter) => ApiClient(
  baseUrl: 'http://api.test/api',
  dio: Dio()..httpClientAdapter = adapter,
);
