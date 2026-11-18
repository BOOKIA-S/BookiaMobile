import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/staff/domain/entities/staff_profile.dart';

/// Repository (PAT-01). Every method throws a `Failure` on error.
abstract interface class StaffRepository {
  /// `GET /auth/me`: the staff account and its store.
  Future<StaffProfile> getProfile();

  /// `GET /reservations/manage`, most recent first. A store owner only sees
  /// its own store.
  Future<List<Reservation>> listReservations();

  /// `PATCH /reservations/:id/status` to `confirmada`.
  Future<Reservation> confirm(String reservationId);

  /// `PATCH /reservations/:id/status` to `cancelada` (copies return to stock).
  Future<Reservation> reject(String reservationId);
}
