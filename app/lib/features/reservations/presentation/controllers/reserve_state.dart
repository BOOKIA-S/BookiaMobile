import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/offers/reservable_offer.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/usecases/create_reservation.dart';

/// Snapshot taken before the POST, so a later quantity change cannot erase
/// what was actually requested.
class ReservationAttempt {
  const ReservationAttempt({
    required this.offerId,
    required this.quantity,
    required this.startedAt,
    required this.session,
  });

  final String offerId;
  final int quantity;

  /// UTC instant when the request was about to be sent.
  final DateTime startedAt;

  /// Session that owned the request; compared by identity.
  final SignedInSession session;
}

/// Explicit lifecycle of screen 10.
sealed class ReserveStatus {
  const ReserveStatus();
}

final class ReservePrepared extends ReserveStatus {
  const ReservePrepared();
}

final class ReserveSending extends ReserveStatus {
  const ReserveSending(this.attempt);

  final ReservationAttempt attempt;
}

final class ReserveSucceeded extends ReserveStatus {
  const ReserveSucceeded(this.reservation);

  final Reservation reservation;
}

final class ReserveFailed extends ReserveStatus {
  const ReserveFailed();
}

final class ReserveUncertain extends ReserveStatus {
  const ReserveUncertain(this.attempt);

  final ReservationAttempt attempt;
}

final class ReserveVerifying extends ReserveStatus {
  const ReserveVerifying(this.attempt);

  final ReservationAttempt attempt;
}

final class ReserveCandidates extends ReserveStatus {
  const ReserveCandidates(this.attempt, this.candidates);

  final ReservationAttempt attempt;
  final List<Reservation> candidates;
}

class ReserveState {
  const ReserveState({
    required this.offer,
    this.quantity = 1,
    this.status = const ReservePrepared(),
    this.failure,
    this.notice,
  });

  final ReservableOffer offer;
  final int quantity;
  final ReserveStatus status;

  /// Definitive error or the last verification error.
  final Failure? failure;

  /// Local explanation (session changed, attempt discarded).
  final String? notice;

  /// 1 to min(5, stock); 0 means sold out and is never selectable.
  int get maxQuantity => offer.stock < CreateReservation.maxQuantity
      ? offer.stock
      : CreateReservation.maxQuantity;

  double get total => offer.price * quantity;

  ReservationAttempt? get attempt => switch (status) {
    ReserveSending(:final attempt) => attempt,
    ReserveUncertain(:final attempt) => attempt,
    ReserveVerifying(:final attempt) => attempt,
    ReserveCandidates(:final attempt) => attempt,
    _ => null,
  };

  Reservation? get created => switch (status) {
    ReserveSucceeded(:final reservation) => reservation,
    _ => null,
  };

  List<Reservation> get candidates => switch (status) {
    ReserveCandidates(:final candidates) => candidates,
    _ => const [],
  };

  bool get isSending => status is ReserveSending;

  bool get isVerifying => status is ReserveVerifying;

  bool get isBusy => isSending || isVerifying;

  /// A previous attempt may still exist on the server: no new POST is allowed.
  bool get isLocked =>
      status is ReserveUncertain ||
      status is ReserveVerifying ||
      status is ReserveCandidates;

  bool get canVerify =>
      status is ReserveUncertain || status is ReserveCandidates;

  ReserveState changeQuantity(int value) => ReserveState(
    offer: offer,
    quantity: value,
    status: status,
    failure: failure,
    notice: notice,
  );

  ReserveState transition(
    ReserveStatus next, {
    Failure? failure,
    String? notice,
  }) => ReserveState(
    offer: offer,
    quantity: quantity,
    status: next,
    failure: failure,
    notice: notice,
  );
}
