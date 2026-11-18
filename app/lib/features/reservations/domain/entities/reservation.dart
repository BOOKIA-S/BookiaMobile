import 'package:bookia_mobile/features/reservations/domain/entities/reservation_status.dart';

/// Copies of one offer set aside by a reader (screens 10, 11 and 12).
///
/// `POST /reservations` returns only ids, so [book] and [store] are null right
/// after creating; `GET /reservations/mine` populates them.
class Reservation {
  const Reservation({
    required this.id,
    required this.offerId,
    required this.price,
    required this.quantity,
    required this.status,
    required this.expiresAt,
    this.userId = '',
    this.storeId = '',
    this.bookId = '',
    this.createdAt,
    this.updatedAt,
    this.book,
    this.store,
  });

  final String id;
  final String userId;
  final String offerId;
  final String storeId;
  final String bookId;

  /// Unit price kept by the server when the reservation was made.
  final double price;
  final int quantity;
  final ReservationStatus status;
  final DateTime expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Populated reference of `GET /reservations/mine`.
  final ReservationBook? book;
  final ReservationStore? store;

  /// Amount to pay in the store, with the price confirmed by the server.
  double get total => price * quantity;

  /// Short pickup code of SPECS.md: `BK-` + the last four characters of the
  /// id. It is only for reading aloud; the QR and the API use [id].
  String get shortCode {
    final tail = id.length <= 4 ? id : id.substring(id.length - 4);
    return 'BK-${tail.toUpperCase()}';
  }
}

/// `book` object of a populated reservation.
class ReservationBook {
  const ReservationBook({
    required this.id,
    required this.title,
    required this.author,
  });

  final String id;
  final String title;
  final String author;
}

/// `store` object of a populated reservation.
class ReservationStore {
  const ReservationStore({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.schedule,
  });

  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? schedule;
}
