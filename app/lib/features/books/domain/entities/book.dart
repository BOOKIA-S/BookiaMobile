/// A book with the offer of every store that sells it (screen 07).
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.genre,
    this.publisher,
    this.edition,
    this.isbn,
    this.offers = const [],
  });

  final String id;
  final String title;
  final String author;
  final String? genre;
  final String? publisher;
  final String? edition;
  final String? isbn;
  final List<BookOffer> offers;

  /// Stores with copies first, each group from the cheapest to the most
  /// expensive, so a sold-out store never tops the comparison.
  List<BookOffer> get offersByPrice => [...offers]
    ..sort(
      (a, b) => a.isAvailable != b.isAvailable
          ? (a.isAvailable ? -1 : 1)
          : a.price.compareTo(b.price),
    );

  /// Copies across all stores.
  int get totalStock => offers.fold(0, (sum, o) => sum + o.stock);

  bool get isAvailable => totalStock > 0;

  /// Lowest price among offers with stock, or null when sold out everywhere.
  double? get minPrice {
    final prices = [
      for (final o in offers)
        if (o.isAvailable) o.price,
    ];
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a < b ? a : b);
  }
}

/// What one store asks for a book and how many copies it has.
class BookOffer {
  const BookOffer({
    required this.id,
    required this.price,
    required this.stock,
    required this.store,
  });

  final String id;
  final double price;
  final int stock;
  final OfferStore store;

  bool get isAvailable => stock > 0;

  /// 2 copies or fewer (amber badge, same rule as screen 04).
  bool get isLow => isAvailable && stock <= 2;
}

/// The store of an offer. The list endpoint only sends `_id` and `name`;
/// screen 09 (stores feature) loads the full store.
class OfferStore {
  const OfferStore({required this.id, required this.name, this.address});

  final String id;
  final String name;
  final String? address;
}
