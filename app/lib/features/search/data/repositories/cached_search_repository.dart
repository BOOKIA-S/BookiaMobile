import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/search/data/datasources/local/search_cache_data_source.dart';
import 'package:bookia_mobile/features/search/data/models/cached_search_model.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/entities/recent_search.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/domain/repositories/search_history_repository.dart';
import 'package:bookia_mobile/features/search/domain/repositories/search_repository.dart';

/// Repository (PAT-01) that saves the first page of each search on the phone
/// and returns it when there is no connection (I2-10).
class CachedSearchRepository
    implements SearchRepository, SearchHistoryRepository {
  CachedSearchRepository(this._remote, this._cache, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SearchRepository _remote;
  final SearchCacheDataSource _cache;
  final DateTime Function() _now;

  @override
  Future<BookPage> search({
    String? q,
    SearchFilters filters = const SearchFilters(),
    int page = 1,
  }) async {
    if (page != 1) return _remote.search(q: q, filters: filters, page: page);
    final key = CachedSearchModel.keyFor(q, filters);
    try {
      final result = await _remote.search(q: q, filters: filters);
      await _save(key, q, filters, result);
      return result;
    } on NetworkFailure {
      final saved = _cache.read(key);
      if (saved == null) rethrow;
      return saved.toOfflinePage();
    }
  }

  Future<void> _save(
    String key,
    String? q,
    SearchFilters filters,
    BookPage result,
  ) async {
    // A failing cache must never break a search that worked.
    try {
      await _cache.write(
        CachedSearchModel.fromPage(
          q: q,
          filters: filters,
          page: result,
          savedAt: _now(),
          count: (_cache.read(key)?.count ?? 0) + 1,
        ),
      );
    } on Exception {
      return;
    }
  }

  @override
  Future<int> count({
    String? q,
    SearchFilters filters = const SearchFilters(),
  }) => _remote.count(q: q, filters: filters);

  @override
  Future<FilterOptions> getFilterOptions() => _remote.getFilterOptions();

  @override
  Future<List<RecentSearch>> recent({int limit = 5}) async {
    // The plain "Buscar" tab (no text, no filters) is not a search to offer.
    final entries =
        _cache.all().where((e) => e.q != null || e.genre != null).toList()
          ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return [for (final e in entries.take(limit)) e.toRecentSearch()];
  }
}
