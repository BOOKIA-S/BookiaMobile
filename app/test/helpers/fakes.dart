import 'package:bookia_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:bookia_mobile/features/home/presentation/providers.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/domain/repositories/search_repository.dart';
import 'package:bookia_mobile/features/search/presentation/providers.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

class MockSearchRepository extends Mock implements SearchRepository {}

/// Overrides so app-level tests never hit the network.
List<Override> offlineOverrides({List<String> genres = const ['Novela']}) {
  final home = MockHomeRepository();
  when(home.getGenres).thenAnswer((_) async => genres);
  registerFallbackValue(const SearchFilters());
  final search = MockSearchRepository();
  when(
    () => search.search(
      q: any(named: 'q'),
      filters: any(named: 'filters'),
      page: any(named: 'page'),
    ),
  ).thenAnswer((_) async => const BookPage(items: [], total: 0, page: 1));
  when(
    () => search.count(
      q: any(named: 'q'),
      filters: any(named: 'filters'),
    ),
  ).thenAnswer((_) async => 0);
  when(search.getFilterOptions)
      .thenAnswer((_) async => FilterOptions(genres: genres, stores: const []));
  return [
    homeRepositoryProvider.overrideWithValue(home),
    searchRepositoryProvider.overrideWithValue(search),
  ];
}
