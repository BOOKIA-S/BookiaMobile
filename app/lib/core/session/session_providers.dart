import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session the rest of the app observes (PAT-07). Starts as guest.
class CurrentSession extends Notifier<SessionStatus> {
  @override
  SessionStatus build() => const GuestSession();

  void set(SessionStatus status) => state = status;
}

final currentSessionProvider = NotifierProvider<CurrentSession, SessionStatus>(
  CurrentSession.new,
);
