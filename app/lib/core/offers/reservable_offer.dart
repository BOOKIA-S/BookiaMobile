/// Read model of one store offer that a reader can reserve.
///
/// Shared contract (ARQ-04): reservations and books talk through this type,
/// so neither feature imports the other's internals.
class ReservableOffer {
  const ReservableOffer({
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthor,
    required this.offerId,
    required this.storeName,
    this.storeAddress,
    required this.price,
    required this.stock,
  });

  final String bookId;
  final String bookTitle;
  final String bookAuthor;
  final String offerId;
  final String storeName;
  final String? storeAddress;
  final double price;
  final int stock;

  bool get isAvailable => stock > 0;
}

/// Looks up the offer behind screen 10 without coupling the reservations
/// feature to the books feature.
abstract interface class ReservableOfferSource {
  /// Null when the book or the offer no longer exists.
  Future<ReservableOffer?> find({
    required String bookId,
    required String offerId,
  });
}
