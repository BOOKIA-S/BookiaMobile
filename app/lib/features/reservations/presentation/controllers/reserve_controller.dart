import 'package:bookia_mobile/app/di.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_state.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `bookId` identifies the screen; `offerId` the store row that was tapped.
typedef ReserveKey = ({String bookId, String offerId});

/// Screen 10: loads the offer, keeps the quantity and creates at most one
/// reservation per attempt. Once the outcome is unknown no new POST is sent
/// until the user verifies or explicitly discards the attempt.
class ReserveController extends AsyncNotifier<ReserveState> {
  ReserveController(this.key);

  final ReserveKey key;

  /// Server-clock tolerance for the heuristic candidate filter. It is not a
  /// proof of authorship: the user must confirm every candidate.
  static const verificationTolerance = Duration(minutes: 2);

  @override
  Future<ReserveState> build() async {
    ref.listen<SessionStatus>(currentSessionProvider, (previous, next) {
      if (identical(previous, next)) return;
      final current = state.value;
      if (current == null || current.status is ReservePrepared) return;
      if (!ref.mounted) return;
      state = AsyncData(
        current.transition(
          const ReservePrepared(),
          notice:
              'La sesión cambió; el intento anterior se descartó localmente. '
              'Si la reserva llegó a crearse, sigue activa en el servidor.',
        ),
      );
    });

    final offer = await ref
        .watch(reservableOfferSourceProvider)
        .find(bookId: key.bookId, offerId: key.offerId);
    if (offer == null) {
      throw const NotFoundFailure('Esta oferta ya no está disponible.');
    }
    return ReserveState(offer: offer);
  }

  void increment() {
    final current = state.value;
    if (current == null || current.isBusy) return;
    if (current.quantity < current.maxQuantity) {
      state = AsyncData(current.changeQuantity(current.quantity + 1));
    }
  }

  void decrement() {
    final current = state.value;
    if (current == null || current.isBusy) return;
    if (current.quantity > 1) {
      state = AsyncData(current.changeQuantity(current.quantity - 1));
    }
  }

  Future<void> submit() async {
    final current = state.value;
    if (current == null ||
        current.isBusy ||
        current.isLocked ||
        current.created != null ||
        current.offer.stock < 1) {
      return;
    }
    final session = ref.read(currentSessionProvider);
    if (session is! SignedInSession || session.role != 'reader') {
      state = AsyncData(
        current.transition(
          const ReserveFailed(),
          failure: session is SignedInSession
              ? const ForbiddenFailure(
                  'Solo las cuentas de lector pueden reservar.',
                )
              : const UnauthorizedFailure(),
        ),
      );
      return;
    }

    // Snapshot before the request: a later quantity change must not erase the
    // data of this attempt.
    final attempt = ReservationAttempt(
      offerId: key.offerId,
      quantity: current.quantity,
      startedAt: DateTime.now().toUtc(),
      session: session,
    );
    state = AsyncData(current.transition(ReserveSending(attempt)));
    try {
      final created = await ref
          .read(createReservationProvider)
          .call(offerId: attempt.offerId, quantity: attempt.quantity);
      if (!ref.mounted) return;
      if (!identical(attempt.session, ref.read(currentSessionProvider))) {
        state = AsyncData(
          current.transition(
            const ReservePrepared(),
            notice:
                'La sesión cambió durante la reserva; no se muestra el '
                'resultado del intento anterior.',
          ),
        );
        return;
      }
      state = AsyncData(current.transition(ReserveSucceeded(created)));
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      if (!identical(attempt.session, ref.read(currentSessionProvider))) {
        state = AsyncData(
          current.transition(
            const ReservePrepared(),
            notice:
                'La sesión cambió durante la reserva; no se muestra el '
                'resultado del intento anterior.',
          ),
        );
        return;
      }
      if (_isAmbiguous(failure)) {
        state = AsyncData(
          current.transition(ReserveUncertain(attempt), failure: failure),
        );
      } else {
        state = AsyncData(
          current.transition(const ReserveFailed(), failure: failure),
        );
      }
    }
  }

  /// A timeout or a 5xx/malformed response cannot prove that the server did
  /// not create the reservation. A 4xx is a rejection and is definitive.
  static bool _isAmbiguous(Failure failure) =>
      failure is NetworkFailure || failure is ServerFailure;

  /// Looks for possible reservations created by the uncertain attempt. The
  /// filters are heuristic; they never prove that the POST created one, so a
  /// match is shown for the user to confirm and is never treated as success.
  Future<void> verify() async {
    final current = state.value;
    final attempt = current?.attempt;
    if (current == null || attempt == null || !current.canVerify) return;
    if (!identical(attempt.session, ref.read(currentSessionProvider))) {
      state = AsyncData(
        current.transition(
          const ReservePrepared(),
          notice:
              'La sesión cambió; no se pueden usar los resultados del intento '
              'anterior.',
        ),
      );
      return;
    }
    state = AsyncData(current.transition(ReserveVerifying(attempt)));
    try {
      final mine = await ref.read(reservationRepositoryProvider).listMine();
      if (!ref.mounted) return;
      if (!identical(attempt.session, ref.read(currentSessionProvider))) {
        state = AsyncData(
          current.transition(
            const ReservePrepared(),
            notice:
                'La sesión cambió; no se pueden usar los resultados del '
                'intento anterior.',
          ),
        );
        return;
      }
      // shortcut: there is no reliable pre-intent id snapshot, so these
      // filters only find candidates. Upgrade when the API provides
      // idempotency keys or a created_after filter.
      final earliest = attempt.startedAt.subtract(verificationTolerance);
      final candidates = [
        for (final reservation in mine)
          if (reservation.offerId == attempt.offerId &&
              reservation.status.isActive &&
              reservation.quantity == attempt.quantity &&
              reservation.createdAt != null &&
              !reservation.createdAt!.isBefore(earliest))
            reservation,
      ];
      state = candidates.isEmpty
          ? AsyncData(
              current.transition(
                ReserveUncertain(attempt),
                failure: const ConflictFailure(
                  'No pudimos confirmar si la reserva se creó. Puede que '
                  'exista o no; vuelve a consultar antes de intentarlo de '
                  'nuevo.',
                ),
              ),
            )
          : AsyncData(
              current.transition(ReserveCandidates(attempt, candidates)),
            );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      // A failed verification must not unlock the attempt.
      state = AsyncData(
        current.transition(ReserveUncertain(attempt), failure: failure),
      );
    }
  }

  /// Local discard only: it does not cancel anything on the server.
  void abandon() {
    final current = state.value;
    if (current == null || !current.isLocked) return;
    state = AsyncData(
      current.transition(
        const ReservePrepared(),
        notice:
            'Descartaste la comprobación local. Si la reserva llegó a crearse, '
            'sigue activa en el servidor y no se canceló.',
      ),
    );
  }
}

/// Not auto-dispose: an uncertain attempt must survive leaving and rebuilding
/// screen 10 during the same app session. It is still lost after a full app
/// restart (see the stabilization report).
final reserveControllerProvider =
    AsyncNotifierProvider.family<ReserveController, ReserveState, ReserveKey>(
      ReserveController.new,
      retry: (_, _) => null,
    );
