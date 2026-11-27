import 'dart:async';

import 'package:bookia_mobile/core/notifications/push_providers.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/notifications/presentation/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps the phone's FCM token linked to the signed-in account (screen 13).
/// Observer (PAT-06): reacts to the session and to FCM token refreshes.
/// State: the token registered in the API, or null.
class PushRegistrationController extends Notifier<String?> {
  StreamSubscription<String>? _refresh;

  @override
  String? build() {
    ref.listen<SessionStatus>(currentSessionProvider, (previous, next) {
      if (next is SignedInSession && previous is! SignedInSession) {
        unawaited(register());
      } else if (next is GuestSession && previous != null) {
        _stopRefresh();
        state = null;
      }
    }, fireImmediately: true);
    ref.onDispose(_stopRefresh);
    return null;
  }

  /// Asks for permission and sends the token to `POST /devices`. Push is a
  /// convenience: any error is logged and the app goes on without it.
  Future<void> register() async {
    final push = ref.read(pushServiceProvider);
    if (!push.isAvailable) return;
    try {
      if (!await push.requestPermission()) return;
      final token = await push.getToken();
      if (token == null) return;
      await _send(token);
      _refresh ??= push.onTokenRefresh.listen(
        (token) => unawaited(_send(token)),
      );
    } on Object catch (error) {
      debugPrint('Push token not registered: $error');
    }
  }

  /// Removes the token with `DELETE /devices/:token`. Must run before the
  /// session token is cleared, while the request can still be authorized.
  Future<void> unregister() async {
    _stopRefresh();
    final token = state;
    state = null;
    if (token == null) return;
    try {
      await ref.read(unregisterDeviceTokenProvider)(token);
    } on Object catch (error) {
      debugPrint('Push token not removed: $error');
    }
  }

  Future<void> _send(String token) async {
    final push = ref.read(pushServiceProvider);
    try {
      await ref.read(registerDeviceTokenProvider)(
        token: token,
        platform: push.platform,
      );
      if (ref.mounted) state = token;
    } on Object catch (error) {
      debugPrint('Push token not registered: $error');
    }
  }

  void _stopRefresh() {
    unawaited(_refresh?.cancel());
    _refresh = null;
  }
}

final pushRegistrationProvider =
    NotifierProvider<PushRegistrationController, String?>(
      PushRegistrationController.new,
    );
