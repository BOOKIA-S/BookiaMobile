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
  });

  /// Factory (PAT-05).
  factory BookSummaryDto.fromJson(Map<String, dynamic> json) {
    final offers = json['offers'];
    return BookSummaryDto(
      id: json['_id'] as String,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      publisher: json['publisher'] as String? ?? '',
      minPrice: (json['min_price'] as num?)?.toDouble(),
      totalStock: (json['total_stock'] as num?)?.toInt() ?? 0,
      availableOffers: offers is List
          ? offers
                .whereType<Map<String, dynamic>>()
                .where((o) => o['is_available'] == true)
                .length
          : 0,
    );
  }

  final String id;
  final String title;
  final String author;
  final String publisher;
  final double? minPrice;
  final int totalStock;
  final int availableOffers;
}
