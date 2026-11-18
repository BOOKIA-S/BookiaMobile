import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel (PAT-02) of screen 11 when it was opened without the freshly
/// created reservation (deep link, reload): finds it in `/reservations/mine`.
class ReservationReadyController extends AsyncNotifier<Reservation> {
  ReservationReadyController(this.reservationId);

  final String reservationId;

  @override
  Future<Reservation> build() =>
      ref.watch(findMyReservationProvider).call(reservationId);
}

/// No automatic retry: a missing reservation or an expired token needs a new
/// action from the user, not a repeated request.
final reservationReadyProvider = AsyncNotifierProvider.autoDispose
    .family<ReservationReadyController, Reservation, String>(
      ReservationReadyController.new,
      retry: (_, _) => null,
    );
