import 'package:bookia_mobile/core/notifications/push_message.dart';
import 'package:bookia_mobile/core/notifications/push_service.dart';

/// Push turned off: Firebase is not configured on this build, or the app runs
/// in a test. The app works the same without notifications (S-5).
class DisabledPushService implements PushService {
  const DisabledPushService();

  @override
  bool get isAvailable => false;

  @override
  String get platform => 'android';

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<PushMessage> get onMessage => const Stream.empty();

  @override
  Stream<PushMessage> get onMessageOpenedApp => const Stream.empty();

  @override
  Future<PushMessage?> getInitialMessage() async => null;
}
