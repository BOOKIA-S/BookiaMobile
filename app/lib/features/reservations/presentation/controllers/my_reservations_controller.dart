import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel (PAT-02) of screen 12: the reader's reservations, newest first.
class MyReservationsController extends AsyncNotifier<List<Reservation>> {
  @override
  Future<List<Reservation>> build() =>
      ref.watch(reservationRepositoryProvider).listMine();

  /// Cancels [id] and reloads the list so stock and statuses are the
  /// server's. Throws the Failure so the page can show its message.
  Future<void> cancel(String id) async {
    await ref.read(reservationRepositoryProvider).cancel(id);
    if (!ref.mounted) return;
    ref.invalidateSelf();
    await future;
  }
}

/// No automatic retry: an expired session needs the reader to sign in again.
final myReservationsProvider =
    AsyncNotifierProvider.autoDispose<
      MyReservationsController,
      List<Reservation>
    >(MyReservationsController.new, retry: (_, _) => null);
