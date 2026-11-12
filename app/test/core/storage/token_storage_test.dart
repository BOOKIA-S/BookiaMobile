import 'package:bookia_mobile/core/storage/token_storage.dart';
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
}
