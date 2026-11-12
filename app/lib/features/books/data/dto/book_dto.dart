/// A book of `GET /books/:id` or `GET /books` (`snake_case`, id in `_id`).
class BookDto {
  const BookDto({
    required this.id,
    required this.title,
    required this.author,
    required this.offers,
    this.genre,
    this.publisher,
    this.edition,
    this.isbn,
  });

  /// Factory (PAT-05).
  factory BookDto.fromJson(Map<String, dynamic> json) {
    final offers = json['offers'];
    return BookDto(
      id: json['_id'] as String,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      genre: json['genre'] as String?,
      publisher: json['publisher'] as String?,
      edition: json['edition'] as String?,
      isbn: json['isbn'] as String?,
      offers: offers is List
          ? offers
                .whereType<Map<String, dynamic>>()
                .map(OfferDto.fromJson)
                .toList()
          : const [],
    );
  }

  final String id;
  final String title;
  final String author;
  final String? genre;
  final String? publisher;
  final String? edition;
  final String? isbn;
  final List<OfferDto> offers;
}

/// An offer with its populated `store`.
class OfferDto {
  const OfferDto({
    required this.id,
    required this.price,
    required this.stock,
    required this.store,
  });

  factory OfferDto.fromJson(Map<String, dynamic> json) {
    final store = json['store'];
    return OfferDto(
      id: json['_id'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      store: StoreRefDto.fromJson(
        store is Map<String, dynamic> ? store : const {'_id': ''},
      ),
    );
  }

  final String id;
  final double price;
  final int stock;
  final StoreRefDto store;
}

class StoreRefDto {
  const StoreRefDto({required this.id, required this.name, this.address});

  factory StoreRefDto.fromJson(Map<String, dynamic> json) => StoreRefDto(
    id: json['_id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    address: json['address'] as String?,
  );

  final String id;
  final String name;
  final String? address;
}
