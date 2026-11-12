import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// API URL from `--dart-define=API_BASE_URL=...` (COD-06).
final apiBaseUrlProvider = Provider<String>(
  (_) => const String.fromEnvironment('API_BASE_URL'),
);

/// Singleton (PAT-04): one ApiClient (one Dio) for the whole app.
/// Non auto-dispose providers stay alive for the app's lifetime.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(baseUrl: ref.watch(apiBaseUrlProvider)),
);
