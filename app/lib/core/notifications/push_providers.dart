import 'package:bookia_mobile/core/notifications/disabled_push_service.dart';
import 'package:bookia_mobile/core/notifications/push_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Singleton (PAT-04) PushService. Off by default; `main.dart` overrides it
/// with `FirebasePushService` when Firebase starts.
final pushServiceProvider = Provider<PushService>(
  (_) => const DisabledPushService(),
);
