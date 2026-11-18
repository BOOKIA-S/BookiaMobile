import 'package:bookia_mobile/core/location/location_providers.dart';
import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:bookia_mobile/features/home/presentation/providers.dart';
import 'package:bookia_mobile/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:bookia_mobile/features/onboarding/presentation/providers.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/domain/repositories/search_repository.dart';
import 'package:bookia_mobile/features/search/presentation/providers.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

class MockSearchRepository extends Mock implements SearchRepository {}

class MockLocationService extends Mock implements LocationService {}

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

/// Location already answered and denied: the splash goes straight to Inicio.
List<Override> locationOverrides({
  bool asked = true,
  LocationAccess access = LocationAccess.denied,
}) {
  final location = MockLocationService();
  when(location.checkAccess).thenAnswer((_) async => access);
  when(location.requestAccess).thenAnswer((_) async => access);
  when(location.currentPosition).thenAnswer((_) async => null);
  final onboarding = MockOnboardingRepository();
  when(onboarding.wasLocationAsked).thenAnswer((_) async => asked);
  when(onboarding.markLocationAsked).thenAnswer((_) async {});
  return [
    locationServiceProvider.overrideWithValue(location),
    onboardingRepositoryProvider.overrideWithValue(onboarding),
  ];
}

/// Overrides so app-level tests never hit the network.
/// Without [location], the test brings its own location overrides.
List<Override> offlineOverrides({
  List<String> genres = const ['Novela'],
  bool location = true,
}) {
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
    if (location) ...locationOverrides(),
  ];
}
