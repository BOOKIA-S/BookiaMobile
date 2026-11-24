import 'dart:async';

import 'package:bookia_mobile/app/push_links.dart';
import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/notifications/push_message.dart';
import 'package:bookia_mobile/core/notifications/push_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens the deep link of each push (screen 13 → 11, 12 or 07).
///
/// - Tapped in the background: opens the route at once.
/// - Launched the app: waits until the splash (01) and the location
///   permission (02) are done, so the link is not lost when they navigate.
/// - Arrived in the foreground: shows a SnackBar with a «Ver» action.
///
/// The router guard still applies: a reservation asks for sign-in first.
class PushNavigation {
  PushNavigation({
    required this._push,
    required this._router,
    required this._messenger,
  });

  final PushService _push;
  final GoRouter _router;
  final GlobalKey<ScaffoldMessengerState> _messenger;
  final _subscriptions = <StreamSubscription<PushMessage>>[];
  String? _pending;

  /// Starts listening. Does nothing when push is off.
  Future<void> start() async {
    if (!_push.isAvailable) return;
    _router.routerDelegate.addListener(_openPending);
    _subscriptions
      ..add(_push.onMessageOpenedApp.listen(_open))
      ..add(_push.onMessage.listen(_showInApp));
    final initial = await _push.getInitialMessage();
    if (initial != null) _open(initial);
  }

  void dispose() {
    _router.routerDelegate.removeListener(_openPending);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  void _open(PushMessage message) {
    final route = routeForPush(message.data);
    if (route == null) return;
    _pending = route;
    _openPending();
  }

  void _openPending() {
    final route = _pending;
    if (route == null || _isStarting) return;
    _pending = null;
    unawaited(_router.push(route));
  }

  bool get _isStarting {
    final path = _router.routerDelegate.currentConfiguration.uri.path;
    return path == AppRoutes.splash || path == AppRoutes.locationPermission;
  }

  void _showInApp(PushMessage message) {
    final text = [
      message.title,
      message.body,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join('\n');
    if (text.isEmpty) return;
    final route = routeForPush(message.data);
    _messenger.currentState?.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 6),
        action: route == null
            ? null
            : SnackBarAction(label: 'Ver', onPressed: () => _open(message)),
      ),
    );
  }
}
