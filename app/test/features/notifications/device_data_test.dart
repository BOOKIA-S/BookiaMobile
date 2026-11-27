import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/notifications/data/datasources/device_remote_data_source.dart';
import 'package:bookia_mobile/features/notifications/data/repositories/device_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

DeviceRepositoryImpl _repository(FakeHttpAdapter adapter) =>
    DeviceRepositoryImpl(DeviceRemoteDataSource(fakeApiClient(adapter)));

void main() {
  group('DeviceRemoteDataSource', () {
    test('register posts token and platform to /devices', () async {
      final adapter = FakeHttpAdapter(200, {
        'device': {'_id': 'd1', 'token': 'abc', 'platform': 'android'},
      });

      await DeviceRemoteDataSource(fakeApiClient(adapter))
          .register(token: 'abc', platform: 'android');

      expect(adapter.last!.method, 'POST');
      expect(adapter.last!.path, '/devices');
      expect(adapter.last!.data, {'token': 'abc', 'platform': 'android'});
    });

    test('unregister URL-encodes the FCM token', () async {
      final adapter = FakeHttpAdapter(204, '');

      await DeviceRemoteDataSource(fakeApiClient(adapter))
          .unregister('fcm:APA91/b');

      expect(adapter.last!.method, 'DELETE');
      expect(adapter.last!.path, '/devices/fcm%3AAPA91%2Fb');
    });
  });

  group('DeviceRepositoryImpl', () {
    test('register completes on 200 and 201', () async {
      for (final status in [200, 201]) {
        await expectLater(
          _repository(FakeHttpAdapter(status, {'device': <String, dynamic>{}}))
              .register(token: 'abc', platform: 'ios'),
          completes,
        );
      }
    });

    test('a 400 becomes a Spanish ValidationFailure', () async {
      final repository = _repository(
        FakeHttpAdapter(400, {'message': 'platform must be android or ios'}),
      );

      await expectLater(
        repository.register(token: 'abc', platform: 'web'),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.message,
            'message',
            'No pudimos activar las notificaciones en este teléfono.',
          ),
        ),
      );
    });

    test('other failures pass through', () async {
      await expectLater(
        _repository(FakeHttpAdapter(401, {'message': 'Unauthorized'}))
            .register(token: 'abc', platform: 'android'),
        throwsA(isA<UnauthorizedFailure>()),
      );
      await expectLater(
        _repository(FakeHttpAdapter(500, {})).unregister('abc'),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('unregister completes on 204', () async {
      await expectLater(
        _repository(FakeHttpAdapter(204, '')).unregister('abc'),
        completes,
      );
    });
  });
}
