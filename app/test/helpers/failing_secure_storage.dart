import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage that fails on one operation, to pin the behaviour of the
/// auth layer when the Keychain/Keystore is not available.
class FailingSecureStorage extends FlutterSecureStorage {
  const FailingSecureStorage(this.operation);

  final String operation;

  Never _fail() => throw StateError('secure storage $operation failed');

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => operation == 'read' ? _fail() : super.read(key: key);

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (operation == 'write') _fail();
    await super.write(key: key, value: value);
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (operation == 'delete') _fail();
    await super.delete(key: key);
  }
}
