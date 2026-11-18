import 'package:bookia_mobile/core/network/api_client.dart';

/// Endpoints of `routes/reservationRoutes.js` used by the reader.
class ReservationRemoteDataSource {
  const ReservationRemoteDataSource(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> create({
    required String offerId,
    required int quantity,
  }) => _api.post<Map<String, dynamic>>(
    '/reservations',
    body: {'offer_id': offerId, 'quantity': quantity},
  );

  Future<List<Map<String, dynamic>>> listMine() async {
    final json = await _api.get<Map<String, dynamic>>('/reservations/mine');
    final items = json['items'];
    if (items is! List) {
      throw const FormatException('Invalid reservations response');
    }
    return items.whereType<Map<String, dynamic>>().toList();
  }
}
