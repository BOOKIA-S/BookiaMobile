import 'package:bookia_mobile/core/notifications/push_message.dart';
import 'package:bookia_mobile/core/notifications/push_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// [PushService] backed by Firebase Cloud Messaging.
class FirebasePushService implements PushService {
  FirebasePushService(this._messaging);

  final FirebaseMessaging _messaging;

  /// Starts Firebase with the platform config files. Returns null when they
  /// are missing or Firebase fails, so the app starts without push (COD-06:
  /// the files are never in the repo).
  static Future<PushService?> initialize() async {
    try {
      await Firebase.initializeApp();
      return FirebasePushService(FirebaseMessaging.instance);
    } on Object catch (error) {
      debugPrint('Push disabled: Firebase is not configured ($error)');
      return null;
    }
  }

  @override
  bool get isAvailable => true;

  @override
  String get platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized || AuthorizationStatus.provisional => true,
      _ => false,
    };
  }

  // The API stores FCM registration tokens (API-04) and sends with them; the
  // newer register()/onRegistered flow gives installation IDs instead, which
  // the API does not support yet.
  @override
  // ignore: deprecated_member_use
  Future<String?> getToken() => _messaging.getToken();

  @override
  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get onMessage => FirebaseMessaging.onMessage.map(toPush);

  @override
  Stream<PushMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(toPush);

  @override
  Future<PushMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : toPush(message);
  }

  /// Adapter: keeps only the text and the string values of `data`.
  @visibleForTesting
  static PushMessage toPush(RemoteMessage message) => PushMessage(
    title: message.notification?.title,
    body: message.notification?.body,
    data: {
      for (final entry in message.data.entries)
        if (entry.value is String) entry.key: entry.value as String,
    },
  );
}
