import 'dart:async';

import 'package:bookia_mobile/core/notifications/push_service.dart';

/// Controllable [PushService] for tests.
class FakePushService implements PushService {
  FakePushService({this.allowed = true, this.token = 'token-1'});

  bool allowed;
  String? token;
  int permissionRequests = 0;
  final refreshes = StreamController<String>.broadcast();

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

  Future<void> close() => refreshes.close();
}
