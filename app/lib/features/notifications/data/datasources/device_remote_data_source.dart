import 'package:bookia_mobile/core/network/api_client.dart';

/// Endpoints of `routes/deviceRoutes.js` (API-04, any signed-in role).
class DeviceRemoteDataSource {
  const DeviceRemoteDataSource(this._api);

  final ApiClient _api;

  /// `POST /devices` -> `{ device: { _id, token, platform, ... } }`.
  Future<Map<String, dynamic>> register({
    required String token,
    required String platform,
  }) => _api.post<Map<String, dynamic>>(
    '/devices',
    body: {'token': token, 'platform': platform},
  );

  /// `DELETE /devices/:token` -> 204. FCM tokens contain `:`, so the token is
  /// URL-encoded.
  Future<void> unregister(String token) async {
    await _api.delete<Object?>('/devices/${Uri.encodeComponent(token)}');
  }
}
