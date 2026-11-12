/// Where the session token lives (SEG-01).
///
/// The real implementation uses `flutter_secure_storage` and arrives with the
/// secure TokenStorage of I5-05; until then [MemoryTokenStore] keeps the app
/// working as a guest.
abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

/// Volatile store: nothing survives a restart. Used by default and in tests.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this._token]);

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> delete() async => _token = null;
}
