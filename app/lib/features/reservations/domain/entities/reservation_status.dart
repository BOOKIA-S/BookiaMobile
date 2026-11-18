/// State pattern (PAT-10): the API status of a reservation and the actions it
/// allows. Unknown values are kept verbatim instead of becoming pending.
sealed class ReservationStatus {
  const ReservationStatus();

  /// Spanish label shown on screens 11 and 12.
  String get label;

  /// Still holds copies: it can be cancelled and its pickup code is valid.
  bool get isActive => this is Pending || this is Confirmed;

  /// Reader may cancel it (`PATCH /reservations/:id/cancel`).
  bool get canCancel => isActive;
}

final class Pending extends ReservationStatus {
  const Pending();

  @override
  String get label => 'Pendiente';
}

final class Confirmed extends ReservationStatus {
  const Confirmed();

  @override
  String get label => 'Confirmada';
}

final class Delivered extends ReservationStatus {
  const Delivered();

  @override
  String get label => 'Entregada';
}

final class Cancelled extends ReservationStatus {
  const Cancelled();

  @override
  String get label => 'Cancelada';
}

final class Expired extends ReservationStatus {
  const Expired();

  @override
  String get label => 'Vencida';
}

/// A status added to the API that this app version does not know yet.
final class UnknownReservationStatus extends ReservationStatus {
  const UnknownReservationStatus(this.raw);

  /// Value exactly as the API sent it.
  final String raw;

  @override
  String get label => 'Estado desconocido';
}
