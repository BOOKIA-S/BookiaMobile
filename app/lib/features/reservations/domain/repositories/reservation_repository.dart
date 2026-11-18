import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';

/// Repository (PAT-01). Every method throws a `Failure` on error.
abstract interface class ReservationRepository {
  /// `POST /reservations` `{ offer_id, quantity }` -> 201 pending reservation.
  Future<Reservation> create({required String offerId, required int quantity});

  /// `GET /reservations/mine`, most recent first.
  Future<List<Reservation>> listMine();

  /// `PATCH /reservations/:id/cancel` -> the cancelled reservation. The copies
  /// return to stock; 409 when it is no longer active (screen 12).
  Future<Reservation> cancel(String id);
}
