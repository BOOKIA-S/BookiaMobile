import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/staff/domain/entities/store_panel.dart';
import 'package:bookia_mobile/features/staff/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel (PAT-02) of screen 16: loads the panel and applies the
/// confirm and reject actions. [confirm] and [reject] throw a Failure when
/// the API refuses; the panel keeps its last data.
class StorePanelController extends AsyncNotifier<StorePanel> {
  @override
  Future<StorePanel> build() => ref.read(loadStorePanelProvider).call();

  Future<void> confirm(String reservationId) =>
      _apply(ref.read(staffRepositoryProvider).confirm(reservationId));

  Future<void> reject(String reservationId) =>
      _apply(ref.read(staffRepositoryProvider).reject(reservationId));

  Future<void> _apply(Future<Reservation> request) async {
    final updated = await request;
    final current = state.value;
    if (current != null) state = AsyncData(current.withReservation(updated));
  }
}

final storePanelProvider =
    AsyncNotifierProvider.autoDispose<StorePanelController, StorePanel>(
      StorePanelController.new,
    );
