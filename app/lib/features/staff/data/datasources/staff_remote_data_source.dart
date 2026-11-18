import 'package:bookia_mobile/core/network/api_client.dart';

/// Endpoints of the reservation desk used by screen 16.
class StaffRemoteDataSource {
  const StaffRemoteDataSource(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> me() =>
      _api.get<Map<String, dynamic>>('/auth/me');

  Future<List<Map<String, dynamic>>> manage() async {
    final json = await _api.get<Map<String, dynamic>>('/reservations/manage');
    final items = json['items'];
    if (items is! List) {
      throw const FormatException('Invalid reservations response');
    }
    final reservations = <Map<String, dynamic>>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid reservation item');
      }
      reservations.add(item);
    }
    return reservations;
  }

  Future<Map<String, dynamic>> setStatus(String id, String status) =>
      _api.patch<Map<String, dynamic>>(
        '/reservations/$id/status',
        body: {'status': status},
      );
}
