import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/core/storage/token_store.dart';
import 'package:bookia_mobile/features/splash/data/repositories/session_repository_impl.dart';
import 'package:bookia_mobile/features/splash/domain/entities/session_status.dart';
import 'package:bookia_mobile/features/splash/domain/repositories/session_repository.dart';
import 'package:bookia_mobile/features/splash/domain/usecases/check_stored_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden by the secure TokenStorage when I5-05 lands (SEG-01).
final tokenStoreProvider = Provider<TokenStore>((_) => MemoryTokenStore());

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepositoryImpl(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
  ),
);

final checkStoredSessionProvider = Provider<CheckStoredSession>(
  (ref) => CheckStoredSession(ref.watch(sessionRepositoryProvider)),
);

/// Session the rest of the app observes (PAT-07). Starts as guest.
class CurrentSession extends Notifier<SessionStatus> {
  @override
  SessionStatus build() => const GuestSession();

  void set(SessionStatus status) => state = status;
}

final currentSessionProvider = NotifierProvider<CurrentSession, SessionStatus>(
  CurrentSession.new,
);
