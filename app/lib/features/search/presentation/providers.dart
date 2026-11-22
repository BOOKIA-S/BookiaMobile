import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/features/search/data/datasources/local/search_cache_data_source.dart';
import 'package:bookia_mobile/features/search/data/repositories/cached_search_repository.dart';
import 'package:bookia_mobile/features/search/data/repositories/search_repository_impl.dart';
import 'package:bookia_mobile/features/search/domain/entities/recent_search.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/domain/repositories/search_history_repository.dart';
import 'package:bookia_mobile/features/search/domain/repositories/search_repository.dart';
import 'package:bookia_mobile/features/search/presentation/search_query.dart';
import 'package:bookia_mobile/features/stores/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where searches are kept offline. main overrides it with the Hive box;
/// without the override (widget tests) they live only in memory.
final searchCacheProvider = Provider<SearchCacheDataSource>(
  (_) => MemorySearchCacheDataSource(),
);

final _cachedSearchRepositoryProvider = Provider<CachedSearchRepository>(
  (ref) => CachedSearchRepository(
    SearchRepositoryImpl(ref.watch(apiClientProvider)),
    ref.watch(searchCacheProvider),
  ),
);

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => ref.watch(_cachedSearchRepositoryProvider),
);

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>(
  (ref) => ref.watch(_cachedSearchRepositoryProvider),
);

/// Chips of "Búsquedas recientes" on screen 03.
final recentSearchesProvider = FutureProvider.autoDispose<List<RecentSearch>>(
  (ref) => ref.watch(searchHistoryRepositoryProvider).recent(),
);

/// Genres and stores of the filters sheet (screen 05).
final filterOptionsProvider = FutureProvider.autoDispose<FilterOptions>(
  (ref) => ref.watch(searchRepositoryProvider).getFilterOptions(),
);

/// "Ver N resultados": matches for the filters being edited.
final resultCountProvider = FutureProvider.autoDispose.family<int, SearchQuery>(
  (ref, query) => ref
      .watch(searchRepositoryProvider)
      .count(q: query.q, filters: query.filters),
);

/// Whether "Más cerca" can be offered: needs the position of the user.
final canSortByDistanceProvider = Provider.autoDispose<bool>(
  (ref) => ref.watch(userPositionProvider) != null,
);

/// Kilometres from the user to each store, from `/stores/near`. Empty when
/// the position is unknown (screen 02 declined or no GPS).
final storeDistancesProvider = FutureProvider.autoDispose<Map<String, double>>((
  ref,
) async {
  final position = ref.watch(userPositionProvider);
  if (position == null) return const {};
  final stores = await ref
      .watch(storeRepositoryProvider)
      .getStores(lat: position.lat, lng: position.lng);
  return {
    for (final s in stores)
      if (s.distanceKm case final double km) s.id: km,
  };
});
