import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/core/storage/token_store.dart';
import 'package:bookia_mobile/features/splash/data/repositories/session_repository_impl.dart';
import 'package:bookia_mobile/features/splash/domain/repositories/session_repository.dart';
import 'package:bookia_mobile/features/splash/domain/usecases/check_stored_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:bookia_mobile/core/session/session_providers.dart'
    show currentSessionProvider;

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => ref.watch(tokenStorageProvider),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepositoryImpl(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
  ),
);

final checkStoredSessionProvider = Provider<CheckStoredSession>(
  (ref) => CheckStoredSession(ref.watch(sessionRepositoryProvider)),
);
