import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/features/home/data/dto/book_filters_dto.dart';
import 'package:bookia_mobile/features/search/data/dto/book_summary_dto.dart';
import 'package:bookia_mobile/features/search/data/dto/store_option_dto.dart';
import 'package:bookia_mobile/features/search/data/mappers/book_summary_mapper.dart';
import 'package:bookia_mobile/features/search/data/mappers/filter_options_mapper.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this._api);

  static const pageSize = 20;
  final ApiClient _api;

  /// Query of `GET /books`; ApiClient drops the null values.
  static Map<String, Object?> _query(String? q, SearchFilters f) => {
    'q': q,
    'genre': f.genre,
    'store_id': f.storeId,
    'min_price': f.minPrice?.round(),
    'max_price': f.maxPrice?.round(),
  };

  @override
  Future<BookPage> search({
    String? q,
    SearchFilters filters = const SearchFilters(),
    int page = 1,
  }) async {
    final json = await _api.get<Map<String, dynamic>>(
      '/books',
      query: {..._query(q, filters), 'page': page, 'limit': pageSize},
    );
    final items = (json['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((e) => BookSummaryDto.fromJson(e).toEntity())
        .toList();
    return BookPage(
      items: items,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      page: (json['page'] as num?)?.toInt() ?? page,
    );
  }

  @override
  Future<int> count({
    String? q,
    SearchFilters filters = const SearchFilters(),
  }) async {
    final json = await _api.get<Map<String, dynamic>>(
      '/books',
      query: {..._query(q, filters), 'page': 1, 'limit': 1},
    );
    return (json['total'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<FilterOptions> getFilterOptions() async {
    // Future.wait rethrows the first Failure as is (ARQ-05).
    final bodies = await Future.wait<Object?>([
      _api.get<Map<String, dynamic>>('/books/filters'),
      _api.get<List<dynamic>>('/stores'),
    ]);
    final filters = bodies[0]! as Map<String, dynamic>;
    final stores = bodies[1]! as List<dynamic>;
    return toFilterOptions(
      BookFiltersDto.fromJson(filters),
      stores
          .whereType<Map<String, dynamic>>()
          .map(StoreOptionDto.fromJson)
          .toList(),
    );
  }
}
