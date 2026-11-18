import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/repositories/reservation_repository.dart';

/// Screen 11 opened from a deep link or after a reload: the API has no
/// `GET /reservations/:id`, so the reservation is found in `/reservations/mine`.
class FindMyReservation {
  const FindMyReservation(this._repository);

  final ReservationRepository _repository;

  Future<Reservation> call(String id) async {
    for (final reservation in await _repository.listMine()) {
      if (reservation.id == id) return reservation;
    }
    throw const NotFoundFailure('No encontramos esta reserva.');
  }
}
