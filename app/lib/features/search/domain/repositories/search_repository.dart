import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';

abstract interface class SearchRepository {
  /// One page of `GET /books`. Throws a Failure on error.
  Future<BookPage> search({
    String? q,
    SearchFilters filters = const SearchFilters(),
    int page = 1,
  });

  /// How many books match, for "Ver N resultados" (screen 05).
  Future<int> count({String? q, SearchFilters filters = const SearchFilters()});

  /// Genres of `/books/filters` and stores of `/stores` for screen 05.
  Future<FilterOptions> getFilterOptions();
}
