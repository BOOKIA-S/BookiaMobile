import 'dart:async';

import 'package:bookia_mobile/core/notifications/push_message.dart';
import 'package:bookia_mobile/core/notifications/push_service.dart';

/// Controllable [PushService] for tests.
class FakePushService implements PushService {
  FakePushService({this.allowed = true, this.token = 'token-1'});

  bool allowed;
  String? token;
  int permissionRequests = 0;
  final refreshes = StreamController<String>.broadcast();
  final messages = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();
  PushMessage? initial;

  @override
  bool get isAvailable => true;

  @override
  String get platform => 'ios';

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allowed;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => refreshes.stream;

  @override
  Stream<PushMessage> get onMessage => messages.stream;

  @override
  Stream<PushMessage> get onMessageOpenedApp => opened.stream;

  @override
  Future<PushMessage?> getInitialMessage() async => initial;

  Future<void> close() async {
    await refreshes.close();
    await messages.close();
    await opened.close();
  }
}
