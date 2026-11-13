import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// API URL from `--dart-define=API_BASE_URL=...` (COD-06).
final apiBaseUrlProvider = Provider<String>(
  (_) => const String.fromEnvironment('API_BASE_URL'),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (_) => const TokenStorage(),
);

final authInterceptorProvider = Provider<AuthInterceptor>(
  (ref) => AuthInterceptor(
    baseUrl: ref.watch(apiBaseUrlProvider),
    tokens: ref.watch(tokenStorageProvider),
    onUnauthorized: () =>
        ref.read(currentSessionProvider.notifier).set(const GuestSession()),
  ),
);

final dioProvider = Provider<Dio>((_) => Dio());

/// Singleton (PAT-04): one ApiClient (one Dio) for the whole app.
/// Non auto-dispose providers stay alive for the app's lifetime.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    baseUrl: ref.watch(apiBaseUrlProvider),
    extraInterceptors: [ref.watch(authInterceptorProvider)],
    dio: ref.watch(dioProvider),
  ),
);
