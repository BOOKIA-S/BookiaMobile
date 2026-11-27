import 'package:bookia_mobile/core/network/api_client.dart';

/// Endpoints of screen 15. The Bearer header comes from AuthInterceptor.
class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> me() =>
      _api.get<Map<String, dynamic>>('/auth/me');

  Future<Map<String, dynamic>> updateName(String name) =>
      _api.patch<Map<String, dynamic>>('/auth/me', body: {'name': name});

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _api.patch<Map<String, dynamic>>(
    '/auth/password',
    body: {'current_password': currentPassword, 'new_password': newPassword},
  );

  Future<Map<String, dynamic>> reservationsMine() =>
      _api.get<Map<String, dynamic>>('/reservations/mine');
}
