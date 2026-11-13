import 'package:bookia_mobile/core/storage/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage implements TokenStore {
  const TokenStorage({this.storage = const FlutterSecureStorage()});

  static const _key = 'auth_token';
  final FlutterSecureStorage storage;

  Future<String?> readToken() => storage.read(key: _key);

  Future<void> saveToken(String token) =>
      storage.write(key: _key, value: token);

  Future<void> clearToken() => storage.delete(key: _key);

  @override
  Future<String?> read() => readToken();

  @override
  Future<void> write(String token) => saveToken(token);

  @override
  Future<void> delete() => clearToken();
}
