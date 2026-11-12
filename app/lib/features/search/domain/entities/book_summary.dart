enum Availability { available, low, soldOut }

/// One row of the results list (screen 04).
class BookSummary {
  const BookSummary({
    required this.id,
    required this.title,
    required this.author,
    required this.publisher,
    required this.minPrice,
    required this.totalStock,
    required this.storeCount,
  });

  final String id;
  final String title;
  final String author;
  final String publisher;

  /// Lowest price among offers with stock, or null if sold out everywhere.
  final double? minPrice;
  final int totalStock;

  /// Stores that have at least one copy.
  final int storeCount;

  /// Green when in stock, amber when 2 or fewer copies, grey when sold out.
  Availability get availability => totalStock <= 0
      ? Availability.soldOut
      : totalStock <= 2
      ? Availability.low
      : Availability.available;
}

/// One page of `GET /books`.
class BookPage {
  const BookPage({
    required this.items,
    required this.total,
    required this.page,
  });

  final List<BookSummary> items;
  final int total;
  final int page;
}
