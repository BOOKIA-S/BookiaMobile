/// A reservation of `POST /reservations` (ids only) or
/// `GET /reservations/mine` (with populated `book` and `store`).
class ReservationDto {
  const ReservationDto({
    required this.id,
    required this.offerId,
    required this.userId,
    required this.storeId,
    required this.bookId,
    required this.price,
    required this.quantity,
    required this.status,
    required this.expiresAt,
    this.createdAt,
    this.updatedAt,
    this.book,
    this.store,
  });

  /// Factory (PAT-05). Throws [FormatException] on a response the app cannot
  /// represent safely.
  factory ReservationDto.fromJson(Map<String, dynamic> json) {
    final id = _idOf(json['_id']);
    final offerId = _idOf(json['offer_id']);
    final storeId = _idOf(json['store_id']);
    final bookId = _idOf(json['book_id']);
    final price = (json['price'] as num?)?.toDouble();
    final quantity = _quantity(json['quantity']);
    final status = json['status'];
    final expiresAt = DateTime.tryParse('${json['expires_at']}');
    if (id == null ||
        offerId == null ||
        storeId == null ||
        bookId == null ||
        price == null ||
        !price.isFinite ||
        price < 0 ||
        quantity == null ||
        status is! String ||
        status.isEmpty ||
        expiresAt == null) {
      throw const FormatException('Invalid reservation');
    }
    return ReservationDto(
      id: id,
      offerId: offerId,
      userId: _idOf(json['user_id']) ?? '',
      storeId: storeId,
      bookId: bookId,
      price: price,
      quantity: quantity,
      status: status,
      expiresAt: expiresAt,
      createdAt: _dateOrNull(json['created_at']),
      updatedAt: _dateOrNull(json['updated_at']),
      book: _book(json['book']),
      store: _store(json['store']),
    );
  }

  final String id;
  final String offerId;
  final String userId;
  final String storeId;
  final String bookId;
  final double price;
  final int quantity;
  final String status;
  final DateTime expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ReservationBookDto? book;
  final ReservationStoreDto? store;

  /// Ids arrive as a string, or as a populated `{ _id }` object.
  static String? _idOf(Object? value) => switch (value) {
    final String id when id.isNotEmpty => id,
    final Map<Object?, Object?> map when map['_id'] is String =>
      (map['_id'] as String).isEmpty ? null : map['_id'] as String,
    _ => null,
  };

  /// Only finite integers from 1 to 5 are accepted; 1.5 is a contract error,
  /// not a silent 1.
  static int? _quantity(Object? value) {
    if (value is! num || !value.isFinite) return null;
    if (value != value.roundToDouble()) return null;
    final quantity = value.toInt();
    return quantity >= 1 && quantity <= 5 ? quantity : null;
  }

  static DateTime? _dateOrNull(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static ReservationBookDto? _book(Object? value) =>
      value is Map<String, dynamic> ? ReservationBookDto.fromJson(value) : null;

  static ReservationStoreDto? _store(Object? value) =>
      value is Map<String, dynamic>
      ? ReservationStoreDto.fromJson(value)
      : null;
}

class ReservationBookDto {
  const ReservationBookDto({
    required this.id,
    required this.title,
    required this.author,
  });

  factory ReservationBookDto.fromJson(Map<String, dynamic> json) =>
      ReservationBookDto(
        id: ReservationDto._idOf(json['_id']) ?? '',
        title: json['title'] as String? ?? '',
        author: json['author'] as String? ?? '',
      );

  final String id;
  final String title;
  final String author;
}

class ReservationStoreDto {
  const ReservationStoreDto({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.schedule,
  });

  factory ReservationStoreDto.fromJson(Map<String, dynamic> json) =>
      ReservationStoreDto(
        id: ReservationDto._idOf(json['_id']) ?? '',
        name: json['name'] as String? ?? '',
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        schedule: json['schedule'] as String?,
      );

  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? schedule;
}
