/// A store offer of `GET /stores/:id` (`snake_case`, ids in `_id`).
class StoreOfferDto {
  const StoreOfferDto({
    required this.id,
    required this.bookId,
    required this.title,
    required this.author,
    required this.price,
    required this.stock,
    required this.isAvailable,
  });

  /// Factory (PAT-05).
  factory StoreOfferDto.fromJson(Map<String, dynamic> json) {
    final book = json['book'];
    final bookJson = book is Map<String, dynamic>
        ? book
        : const <String, dynamic>{};
    return StoreOfferDto(
      id: json['_id'] as String,
      bookId: bookJson['_id'] as String? ?? '',
      title: bookJson['title'] as String? ?? '',
      author: bookJson['author'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isAvailable: json['is_available'] == true,
    );
  }

  final String id;
  final String bookId;
  final String title;
  final String author;
  final double price;
  final int stock;
  final bool isAvailable;
}

/// Body of `GET /stores/:id`: the store fields plus its `offers`.
class StoreDetailDto {
  const StoreDetailDto({
    required this.id,
    required this.name,
    required this.address,
    required this.offers,
    this.phone,
    this.schedule,
    this.mapsUrl,
    this.lat,
    this.lng,
  });

  /// Factory (PAT-05).
  factory StoreDetailDto.fromJson(Map<String, dynamic> json) => StoreDetailDto(
    id: json['_id'] as String,
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String?,
    schedule: json['schedule'] as String?,
    mapsUrl: json['maps_url'] as String?,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    offers: (json['offers'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(StoreOfferDto.fromJson)
        .toList(),
  );

  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? schedule;
  final String? mapsUrl;
  final double? lat;
  final double? lng;
  final List<StoreOfferDto> offers;
}
