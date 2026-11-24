import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/entities/recent_search.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';

/// What the phone keeps of one search in Hive (I2-10). Books are stored as
/// plain maps so the box needs a single TypeAdapter.
class CachedSearchModel {
  const CachedSearchModel({
    required this.key,
    required this.q,
    required this.genre,
    required this.storeId,
    required this.minPrice,
    required this.maxPrice,
    required this.count,
    required this.savedAt,
    required this.books,
  });

  /// Builds a new entry for the first page of a search.
  factory CachedSearchModel.fromPage({
    required String? q,
    required SearchFilters filters,
    required BookPage page,
    required DateTime savedAt,
    int count = 1,
  }) => CachedSearchModel(
    key: keyFor(q, filters),
    q: q,
    genre: filters.genre,
    storeId: filters.storeId,
    minPrice: filters.minPrice,
    maxPrice: filters.maxPrice,
    count: count,
    savedAt: savedAt,
    books: [for (final b in page.items) bookToMap(b)],
  );

  final String key;
  final String? q;
  final String? genre;
  final String? storeId;
  final double? minPrice;
  final double? maxPrice;
  final int count;
  final DateTime savedAt;
  final List<Map<String, Object?>> books;

  /// Only the filters the API applies; order and "Solo disponibles" are
  /// applied on the phone and share the same cached page.
  static String keyFor(String? q, SearchFilters f) => [
    q?.trim().toLowerCase() ?? '',
    f.genre ?? '',
    f.storeId ?? '',
    f.minPrice?.round() ?? '',
    f.maxPrice?.round() ?? '',
  ].join('|');

  static Map<String, Object?> bookToMap(BookSummary b) => {
    'id': b.id,
    'title': b.title,
    'author': b.author,
    'publisher': b.publisher,
    'min_price': b.minPrice,
    'total_stock': b.totalStock,
    'store_count': b.storeCount,
    'store_ids': b.storeIds,
  };

  static BookSummary bookFromMap(Map<Object?, Object?> m) => BookSummary(
    id: m['id'] as String? ?? '',
    title: m['title'] as String? ?? '',
    author: m['author'] as String? ?? '',
    publisher: m['publisher'] as String? ?? '',
    minPrice: (m['min_price'] as num?)?.toDouble(),
    totalStock: (m['total_stock'] as num?)?.toInt() ?? 0,
    storeCount: (m['store_count'] as num?)?.toInt() ?? 0,
    storeIds: [...?(m['store_ids'] as List?)?.whereType<String>()],
  );

  List<BookSummary> get bookEntities => [for (final m in books) bookFromMap(m)];

  /// The page shown on screen 04 when the API cannot be reached.
  BookPage toOfflinePage() {
    final items = bookEntities;
    return BookPage(
      items: items,
      total: items.length,
      page: 1,
      savedAt: savedAt,
    );
  }

  RecentSearch toRecentSearch() => RecentSearch(
    key: key,
    q: q,
    filters: SearchFilters(
      genre: genre,
      storeId: storeId,
      minPrice: minPrice,
      maxPrice: maxPrice,
    ),
    count: count,
    lastSearchedAt: savedAt,
    books: bookEntities,
  );
}
