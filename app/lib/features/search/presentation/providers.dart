import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/features/search/data/repositories/search_repository_impl.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/domain/repositories/search_repository.dart';
import 'package:bookia_mobile/features/search/presentation/search_query.dart';
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
