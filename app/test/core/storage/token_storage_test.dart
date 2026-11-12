import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/core/storage/token_storage.dart';
import 'package:bookia_mobile/features/splash/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stores, reads and removes only the auth token', () async {
    FlutterSecureStorage.setMockInitialValues({'other': 'keep'});
    const tokens = TokenStorage();
    expect(await tokens.readToken(), isNull);
    await tokens.saveToken('secret');
    expect(await tokens.readToken(), 'secret');
    await tokens.clearToken();
    expect(await tokens.readToken(), isNull);
    expect(await const FlutterSecureStorage().read(key: 'other'), 'keep');
  });

  test(
    'splash and the interceptor share the same secure token store',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('https://bookia.test/api'),
        ],
      );
      addTearDown(container.dispose);
      final tokens = container.read(tokenStorageProvider);
      expect(identical(container.read(tokenStoreProvider), tokens), isTrue);
      await tokens.saveToken('fixture-token');
      expect(
        await container.read(sessionRepositoryProvider).hasStoredToken(),
        isTrue,
      );
      await container.read(sessionRepositoryProvider).clearStoredToken();
      expect(await tokens.readToken(), isNull);
    },
  );
}
