/// Repository (PAT-01) of the phone's push token in the API (API-04).
/// Every method throws a `Failure` on error.
abstract interface class DeviceRepository {
  /// `POST /devices { token, platform }`. Idempotent: registering the same
  /// token again only refreshes it.
  Future<void> register({required String token, required String platform});

  /// `DELETE /devices/:token`, called before signing out.
  Future<void> unregister(String token);
}
