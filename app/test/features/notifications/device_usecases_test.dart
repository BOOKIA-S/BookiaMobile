import 'package:bookia_mobile/features/notifications/domain/repositories/device_repository.dart';
import 'package:bookia_mobile/features/notifications/domain/usecases/register_device_token.dart';
import 'package:bookia_mobile/features/notifications/domain/usecases/unregister_device_token.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeviceRepository extends Mock implements DeviceRepository {}

void main() {
  late _MockDeviceRepository repository;

  setUp(() {
    repository = _MockDeviceRepository();
    when(
      () => repository.register(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async {});
    when(() => repository.unregister(any())).thenAnswer((_) async {});
  });

  group('RegisterDeviceToken', () {
    test('sends the trimmed token with its platform', () async {
      await RegisterDeviceToken(repository)(token: ' abc ', platform: 'ios');

      verify(() => repository.register(token: 'abc', platform: 'ios'));
    });

    test('any platform other than ios is sent as android', () async {
      await RegisterDeviceToken(repository)(token: 'abc', platform: 'fuchsia');

      verify(() => repository.register(token: 'abc', platform: 'android'));
    });

    test('ignores a blank token', () async {
      await RegisterDeviceToken(repository)(token: '  ', platform: 'android');

      verifyNever(
        () => repository.register(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      );
    });
  });

  group('UnregisterDeviceToken', () {
    test('removes the trimmed token', () async {
      await UnregisterDeviceToken(repository)(' abc ');

      verify(() => repository.unregister('abc'));
    });

    test('ignores a blank token', () async {
      await UnregisterDeviceToken(repository)('');

      verifyNever(() => repository.unregister(any()));
    });
  });
}
