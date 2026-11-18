import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/repositories/reservation_repository.dart';

/// Use case of screen 10. The server stays the authority on stock, price,
/// roles and expiry; this only rejects requests the API would reject anyway.
class CreateReservation {
  const CreateReservation(this._repository);

  /// `MAX_RESERVATION_QUANTITY` of the API (utils/reservationRules.js).
  static const maxQuantity = 5;

  final ReservationRepository _repository;

  Future<Reservation> call({required String offerId, required int quantity}) {
    if (offerId.trim().isEmpty) {
      throw const ValidationFailure('Esta oferta ya no es válida.');
    }
    if (quantity < 1 || quantity > maxQuantity) {
      throw const ValidationFailure('Elige de 1 a 5 ejemplares.');
    }
    return _repository.create(offerId: offerId, quantity: quantity);
  }
}
