import 'package:bookia_mobile/core/notifications/disabled_push_service.dart';
import 'package:bookia_mobile/core/notifications/push_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('push is off by default and answers as a refusal', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final push = container.read(pushServiceProvider);

    expect(push, isA<DisabledPushService>());
    expect(push.isAvailable, isFalse);
    expect(push.platform, 'android');
    expect(await push.requestPermission(), isFalse);
    expect(await push.getToken(), isNull);
    expect(await push.onTokenRefresh.isEmpty, isTrue);
    expect(await push.onMessage.isEmpty, isTrue);
    expect(await push.onMessageOpenedApp.isEmpty, isTrue);
    expect(await push.getInitialMessage(), isNull);
  });
}
