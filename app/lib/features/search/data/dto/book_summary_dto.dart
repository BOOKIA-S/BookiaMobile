/// A book of `GET /books` (`snake_case`, id in `_id`).
class BookSummaryDto {
  const BookSummaryDto({
    required this.id,
    required this.title,
    required this.author,
    required this.publisher,
    required this.minPrice,
    required this.totalStock,
    required this.availableOffers,
    this.availableStoreIds = const [],
  });

  /// Factory (PAT-05).
  factory BookSummaryDto.fromJson(Map<String, dynamic> json) {
    final offers = json['offers'];
    final available = offers is List
        ? offers
              .whereType<Map<String, dynamic>>()
              .where((o) => o['is_available'] == true)
              .toList()
        : const <Map<String, dynamic>>[];
    return BookSummaryDto(
      id: json['_id'] as String,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      publisher: json['publisher'] as String? ?? '',
      minPrice: (json['min_price'] as num?)?.toDouble(),
      totalStock: (json['total_stock'] as num?)?.toInt() ?? 0,
      availableOffers: available.length,
      availableStoreIds: [
        for (final o in available)
          if (o['store'] case {'_id': final String id}) id,
      ],
    );
  }

  final String id;
  final String title;
  final String author;
  final String publisher;
  final double? minPrice;
  final int totalStock;
  final int availableOffers;

  /// `offers[].store._id` of the offers with stock.
  final List<String> availableStoreIds;
}
