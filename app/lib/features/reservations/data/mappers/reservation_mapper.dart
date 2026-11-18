import 'package:bookia_mobile/features/reservations/data/dto/reservation_dto.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation_status.dart';

/// Adapter (PAT-07): API DTO to domain entity.
extension ReservationMapper on ReservationDto {
  Reservation toEntity() => Reservation(
    id: id,
    userId: userId,
    offerId: offerId,
    storeId: storeId,
    bookId: bookId,
    price: price,
    quantity: quantity,
    status: reservationStatusFromApi(status),
    expiresAt: expiresAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
    book: switch (book) {
      final b? => ReservationBook(id: b.id, title: b.title, author: b.author),
      null => null,
    },
    store: switch (store) {
      final s? => ReservationStore(
        id: s.id,
        name: s.name,
        address: _orNull(s.address),
        phone: _orNull(s.phone),
        schedule: _orNull(s.schedule),
      ),
      null => null,
    },
  );
}

/// API strings of `utils/reservationRules.js`.
ReservationStatus reservationStatusFromApi(String value) => switch (value) {
  'pendiente' => const Pending(),
  'confirmada' => const Confirmed(),
  'entregada' => const Delivered(),
  'cancelada' => const Cancelled(),
  'vencida' => const Expired(),
  _ => UnknownReservationStatus(value),
};

String? _orNull(String? value) =>
    value == null || value.trim().isEmpty ? null : value;
