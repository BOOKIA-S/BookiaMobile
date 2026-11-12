/// A BOOKIA store (screen 09). Optional fields come as null from the API.
class Store {
  const Store({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.schedule,
    this.mapsUrl,
    this.lat,
    this.lng,
  });

  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? schedule;
  final String? mapsUrl;
  final double? lat;
  final double? lng;
}

/// One book of the store catalog with its price and copies.
class StoreOffer {
  const StoreOffer({
    required this.id,
    required this.bookId,
    required this.title,
    required this.author,
    required this.price,
    required this.stock,
    required this.isAvailable,
  });

  final String id;
  final String bookId;
  final String title;
  final String author;
  final double price;
  final int stock;
  final bool isAvailable;

  /// Amber badge: in stock but 2 copies or fewer.
  bool get isLowStock => isAvailable && stock <= 2;
}

/// Result of `GET /stores/:id`: the store and its catalog.
class StoreDetail {
  const StoreDetail({required this.store, required this.offers});

  final Store store;
  final List<StoreOffer> offers;
}
