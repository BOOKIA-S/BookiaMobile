import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation_status.dart';
import 'package:bookia_mobile/features/staff/domain/entities/staff_profile.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';

/// Everything screen 16 shows: the account, its store and the reservations.
class StorePanel {
  const StorePanel({
    required this.profile,
    required this.reservations,
    this.store,
    this.offers,
  });

  final StaffProfile profile;

  /// Null for an admin, who is not tied to one store.
  final Store? store;

  /// Latest reservations of the desk (`GET /reservations/manage`, up to 200).
  final List<Reservation> reservations;

  /// Catalog of [store]; null when there is no store to read it from.
  final List<StoreOffer>? offers;

  /// Reservations waiting for the staff to confirm them.
  List<Reservation> get pending => [
    for (final r in reservations)
      if (r.status is Pending) r,
  ];

  /// Titles in the catalog, or null without a store.
  int? get catalogTitles => offers?.length;

  /// Offers with no copies left, or null without a store.
  int? get soldOutOffers =>
      offers?.where((o) => !o.isAvailable || o.stock <= 0).length;

  /// Amount set aside in the month of [now]: reservations created that
  /// month that were not cancelled or expired.
  double monthAmount(DateTime now) {
    var total = 0.0;
    for (final r in reservations) {
      final created = r.createdAt?.toLocal();
      final counts =
          r.status is Pending || r.status is Confirmed || r.status is Delivered;
      if (counts &&
          created != null &&
          created.year == now.year &&
          created.month == now.month) {
        total += r.total;
      }
    }
    return total;
  }

  /// Same panel with [updated] in place of the reservation of the same id.
  /// What the answer of the API does not carry (book, store, dates) is kept.
  StorePanel withReservation(Reservation updated) => StorePanel(
    profile: profile,
    store: store,
    offers: offers,
    reservations: [
      for (final r in reservations) r.id == updated.id ? _merge(r, updated) : r,
    ],
  );

  static Reservation _merge(Reservation old, Reservation updated) =>
      Reservation(
        id: old.id,
        userId: old.userId,
        offerId: old.offerId,
        storeId: old.storeId,
        bookId: old.bookId,
        price: updated.price,
        quantity: updated.quantity,
        status: updated.status,
        expiresAt: updated.expiresAt,
        createdAt: updated.createdAt ?? old.createdAt,
        updatedAt: updated.updatedAt ?? old.updatedAt,
        book: updated.book ?? old.book,
        store: updated.store ?? old.store,
      );
}
