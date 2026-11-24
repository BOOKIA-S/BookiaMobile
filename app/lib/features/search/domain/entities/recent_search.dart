import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';

/// A search kept on the phone (I2-10): what was asked, how often, and the
/// first page of results to show without connection.
class RecentSearch {
  const RecentSearch({
    required this.key,
    required this.q,
    required this.filters,
    required this.count,
    required this.lastSearchedAt,
    required this.books,
  });

  /// Identifies the query and its server-side filters.
  final String key;
  final String? q;

  /// Filters the API applied (genre, store and price).
  final SearchFilters filters;

  /// Times it was searched with connection.
  final int count;
  final DateTime lastSearchedAt;

  /// First page of results, as the API answered it last time.
  final List<BookSummary> books;

  /// Text of the chip on screen 03.
  String get label => q ?? filters.genre ?? 'Búsqueda';
}
