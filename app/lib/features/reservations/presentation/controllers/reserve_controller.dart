import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/books/domain/entities/book.dart';
import 'package:bookia_mobile/features/books/presentation/providers.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/usecases/create_reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `bookId` identifies the screen; `offerId` the store row that was tapped.
typedef ReserveKey = ({String bookId, String offerId});

/// ViewModel state (PAT-02) of screen 10.
class ReserveState {
  const ReserveState({
    required this.book,
    required this.offer,
    this.quantity = 1,
    this.isSubmitting = false,
    this.created,
    this.failure,
    this.sentAt,
  });

  final Book book;
  final BookOffer offer;
  final int quantity;
  final bool isSubmitting;

  /// Reservation confirmed by the server; null until it succeeds.
  final Reservation? created;
  final Failure? failure;

  /// Set when a timeout leaves the outcome unknown (no automatic retry).
  final DateTime? sentAt;

  /// 1 to min(5, stock); using a sold-out offer is not possible.
  int get maxQuantity => offer.stock < CreateReservation.maxQuantity
      ? offer.stock
      : CreateReservation.maxQuantity;

  /// Estimate shown before confirming; the server price wins afterwards.
  double get total => offer.price * quantity;

  bool get canVerify => failure is NetworkFailure && sentAt != null;
}

/// Screen 10: loads the offer, keeps the quantity and creates the reservation
/// once. Every path is guarded here, not only on the button.
class ReserveController extends AsyncNotifier<ReserveState> {
  ReserveController(this.key);

  final ReserveKey key;

  @override
  Future<ReserveState> build() async {
    final book = await ref.watch(bookRepositoryProvider).getById(key.bookId);
    BookOffer? offer;
    for (final candidate in book.offers) {
      if (candidate.id == key.offerId) {
        offer = candidate;
        break;
      }
    }
    if (offer == null) {
      throw const NotFoundFailure('Esta oferta ya no está disponible.');
    }
    return ReserveState(book: book, offer: offer);
  }

  void increment() {
    final current = state.value;
    if (current == null || current.isSubmitting) return;
    if (current.quantity < current.maxQuantity) {
      state = AsyncData(_copy(current, quantity: current.quantity + 1));
    }
  }

  void decrement() {
    final current = state.value;
    if (current == null || current.isSubmitting) return;
    if (current.quantity > 1) {
      state = AsyncData(_copy(current, quantity: current.quantity - 1));
    }
  }

  Future<void> submit() async {
    final current = state.value;
    if (current == null ||
        current.isSubmitting ||
        current.created != null ||
        current.offer.stock < 1) {
      return;
    }
    final session = ref.read(currentSessionProvider);
    if (session is! SignedInSession || session.role != 'reader') {
      state = AsyncData(
        _copy(
          current,
          failure: session is SignedInSession
              ? const ForbiddenFailure(
                  'Solo las cuentas de lector pueden reservar.',
                )
              : const UnauthorizedFailure(),
        ),
      );
      return;
    }

    state = AsyncData(_copy(current, isSubmitting: true));
    try {
      final created = await ref
          .read(createReservationProvider)
          .call(offerId: key.offerId, quantity: current.quantity);
      if (!ref.mounted) return;
      state = AsyncData(_copy(current, created: created));
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(
        _copy(
          current,
          failure: failure,
          sentAt: failure is NetworkFailure ? DateTime.now() : null,
        ),
      );
    }
  }

  /// After an ambiguous timeout: looks for a new active reservation of the same
  /// offer instead of sending the POST again. It never creates a duplicate.
  Future<void> verify() async {
    final current = state.value;
    if (current == null || current.isSubmitting || !current.canVerify) return;
    state = AsyncData(_copy(current, isSubmitting: true));
    try {
      final mine = await ref.read(reservationRepositoryProvider).listMine();
      if (!ref.mounted) return;
      Reservation? match;
      for (final reservation in mine) {
        if (reservation.offerId == key.offerId && reservation.status.isActive) {
          match = reservation;
          break;
        }
      }
      state = match == null
          ? AsyncData(
              _copy(
                current,
                failure: const ConflictFailure(
                  'No se creó ninguna reserva nueva. Puedes intentarlo otra vez.',
                ),
              ),
            )
          : AsyncData(_copy(current, created: match));
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(_copy(current, failure: failure));
    }
  }

  /// [failure] and [sentAt] always follow the latest action, so a new attempt
  /// clears the previous error.
  static ReserveState _copy(
    ReserveState current, {
    int? quantity,
    bool? isSubmitting,
    Reservation? created,
    Failure? failure,
    DateTime? sentAt,
  }) => ReserveState(
    book: current.book,
    offer: current.offer,
    quantity: quantity ?? current.quantity,
    isSubmitting: isSubmitting ?? current.isSubmitting,
    created: created ?? current.created,
    failure: failure,
    sentAt: sentAt,
  );
}

/// No automatic retry: a missing offer or an expired token is not fixed by
/// repeating the request; screen 10 offers Reintentar instead.
final reserveControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ReserveController, ReserveState, ReserveKey>(
      ReserveController.new,
      retry: (_, _) => null,
    );
