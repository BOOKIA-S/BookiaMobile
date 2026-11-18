import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/features/search/data/repositories/search_repository_impl.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/domain/repositories/search_repository.dart';
import 'package:bookia_mobile/features/search/presentation/search_query.dart';
import 'package:bookia_mobile/features/stores/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(ref.watch(apiClientProvider)),
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
