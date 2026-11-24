import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/notifications/push_providers.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/notifications/domain/repositories/device_repository.dart';
import 'package:bookia_mobile/features/notifications/presentation/controllers/push_registration_controller.dart';
import 'package:bookia_mobile/features/notifications/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'fake_push_service.dart';

class _MockDeviceRepository extends Mock implements DeviceRepository {}

const _reader = SignedInSession(name: 'Ana', role: 'reader');

void main() {
  late _MockDeviceRepository devices;
  late FakePushService push;

  ProviderContainer container({bool pushAvailable = true}) {
    final c = ProviderContainer(
      overrides: [
        deviceRepositoryProvider.overrideWithValue(devices),
        if (pushAvailable) pushServiceProvider.overrideWithValue(push),
      ],
    );
    addTearDown(c.dispose);
    c.read(pushRegistrationProvider);
    return c;
  }

  Future<void> signIn(ProviderContainer c) async {
    c.read(currentSessionProvider.notifier).set(_reader);
    await pumpEventQueue();
  }

  void verifyRegistered(String token, {int times = 1}) =>
      verify(() => devices.register(token: token, platform: 'ios'))
          .called(times);

  setUp(() {
    devices = _MockDeviceRepository();
    push = FakePushService();
    addTearDown(push.close);
    when(
      () => devices.register(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async {});
    when(() => devices.unregister(any())).thenAnswer((_) async {});
  });

  test('does nothing while the user is a guest', () async {
    final c = container();
    await pumpEventQueue();

    expect(push.permissionRequests, 0);
    expect(c.read(pushRegistrationProvider), isNull);
  });

  test('registers the token after signing in', () async {
    final c = container();
    await signIn(c);

    verifyRegistered('token-1');
    expect(c.read(pushRegistrationProvider), 'token-1');
  });

  test('registers again when FCM refreshes the token', () async {
    final c = container();
    await signIn(c);
    push.refreshes.add('token-2');
    await pumpEventQueue();

    verifyRegistered('token-2');
    expect(c.read(pushRegistrationProvider), 'token-2');
  });

  test('skips the API when the user denies notifications', () async {
    push.allowed = false;
    final c = container();
    await signIn(c);

    verifyNever(
      () => devices.register(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    );
    expect(c.read(pushRegistrationProvider), isNull);
  });

  test('skips everything when Firebase is not configured', () async {
    final c = container(pushAvailable: false);
    await signIn(c);

    verifyNever(
      () => devices.register(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    );
  });

  test('an API error does not break the sign-in', () async {
    when(
      () => devices.register(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenThrow(const NetworkFailure());
    final c = container();
    await signIn(c);

    expect(c.read(pushRegistrationProvider), isNull);
  });

  test('unregister removes the token and stops listening', () async {
    final c = container();
    await signIn(c);

    await c.read(pushRegistrationProvider.notifier).unregister();
    push.refreshes.add('token-3');
    await pumpEventQueue();

    verify(() => devices.unregister('token-1')).called(1);
    verifyNever(() => devices.register(token: 'token-3', platform: 'ios'));
    expect(c.read(pushRegistrationProvider), isNull);
  });

  test('unregister without a token and API errors are ignored', () async {
    final c = container();
    await c.read(pushRegistrationProvider.notifier).unregister();
    verifyNever(() => devices.unregister(any()));

    when(() => devices.unregister(any())).thenThrow(const NetworkFailure());
    await signIn(c);
    await expectLater(
      c.read(pushRegistrationProvider.notifier).unregister(),
      completes,
    );
  });

  test('signing out clears the state', () async {
    final c = container();
    await signIn(c);
    c.read(currentSessionProvider.notifier).set(const GuestSession());

    expect(c.read(pushRegistrationProvider), isNull);
  });
}
