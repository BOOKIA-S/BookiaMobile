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

  Future<Map<String, dynamic>> cancel(String id) =>
      _api.patch<Map<String, dynamic>>(
        '/reservations/${Uri.encodeComponent(id)}/cancel',
      );

  Future<List<Map<String, dynamic>>> listMine() async {
    final json = await _api.get<Map<String, dynamic>>('/reservations/mine');
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
}
