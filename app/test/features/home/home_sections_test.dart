import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/location/location_providers.dart';
import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/features/home/domain/usecases/rank_most_searched.dart';
import 'package:bookia_mobile/features/home/presentation/providers.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:bookia_mobile/features/search/data/datasources/local/search_cache_data_source.dart';
import 'package:bookia_mobile/features/search/data/models/cached_search_model.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/entities/recent_search.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/presentation/providers.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

BookSummary _book(String id, {double? price = 80}) => BookSummary(
  id: id,
  title: 'Libro $id',
  author: 'Autor $id',
  publisher: 'Editorial',
  minPrice: price,
  totalStock: price == null ? 0 : 3,
  storeCount: price == null ? 0 : 1,
);

RecentSearch _search(
  String q,
  int count,
  List<BookSummary> books, {
  int minute = 0,
}) => RecentSearch(
  key: q,
  q: q,
  filters: const SearchFilters(),
  count: count,
  lastSearchedAt: DateTime(2026, 11, 21, 10, minute),
  books: books,
);

/// The vertical list of screen 03 (the carousel scrolls sideways).
final _page = find.byType(Scrollable).first;

const _store = Store(
  id: 's1',
  name: 'Librería del Centro',
  address: 'Av. Juárez 10',
  schedule: 'Lun a sáb 9:00–20:00',
  distanceKm: 0.85,
);

void main() {
  group('rankMostSearched', () {
    test('ranks books by how often their searches were made', () {
      final a = _book('a');
      final b = _book('b');
      final c = _book('c');
      final ranked = rankMostSearched([
        _search('rulfo', 1, [a, b]),
        _search('poesía', 4, [c, b]),
      ]);
      // c: 4, b: 1/2 + 4/2 = 2.5, a: 1.
      expect(ranked.map((x) => x.id), ['c', 'b', 'a']);
    });

    test('keeps the newest copy of a book and breaks ties by recency', () {
      final old = _book('a', price: 120);
      final fresh = _book('a', price: 95);
      final ranked = rankMostSearched([
        _search('x', 1, [old, _book('b')]),
        _search('y', 1, [_book('c'), fresh], minute: 5),
      ]);
      expect(ranked.first.id, 'a');
      expect(ranked.first.minPrice, 95);
      expect(ranked.map((x) => x.id), ['a', 'c', 'b']);
    });

    test('respects the limit and an empty history', () {
      expect(rankMostSearched(const []), isEmpty);
      final many = [for (var i = 0; i < 15; i++) _book('$i')];
      expect(rankMostSearched([_search('q', 1, many)]), hasLength(10));
    });
  });

  group('screen 03', () {
    late MockSearchRepository search;
    late MockStoreRepository stores;

    setUp(() {
      registerFallbackValue(const SearchFilters());
      search = MockSearchRepository();
      stores = MockStoreRepository();
      when(
        () => search.search(
          q: any(named: 'q'),
          filters: any(named: 'filters'),
          page: any(named: 'page'),
        ),
      ).thenAnswer(
        (_) async => BookPage(items: [_book('cat')], total: 1, page: 1),
      );
      when(
        () => stores.getStores(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      ).thenAnswer((_) async => const [_store]);
    });

    Future<GoRouter> pump(
      WidgetTester tester, {
      List<Override> extra = const [],
      GeoPoint? position,
    }) async {
      final location = MockLocationService();
      when(location.currentPosition).thenAnswer((_) async => position);
      final home = MockHomeRepository();
      when(home.getGenres).thenAnswer((_) async => ['Novela']);
      final reservations = MockReservationRepository();
      when(reservations.listMine).thenAnswer((_) async => const []);
      final router = createRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeRepositoryProvider.overrideWithValue(home),
            reservationRepositoryProvider.overrideWithValue(reservations),
            locationServiceProvider.overrideWithValue(location),
            searchRepositoryProvider.overrideWithValue(search),
            storeRepositoryProvider.overrideWithValue(stores),
            ...extra,
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('without history shows catalog books', (tester) async {
      await pump(tester);
      expect(find.text('Más buscados'), findsOneWidget);
      expect(find.text('Del catálogo de BOOKIA'), findsOneWidget);
      expect(find.text('Libro cat'), findsOneWidget);
      expect(find.text(r'desde $80.00'), findsOneWidget);
    });

    testWidgets('with history ranks books searched on the phone', (
      tester,
    ) async {
      final cache = MemorySearchCacheDataSource();
      await cache.write(
        CachedSearchModel.fromPage(
          q: 'rulfo',
          filters: const SearchFilters(),
          page: BookPage(items: [_book('pp', price: null)], total: 1, page: 1),
          savedAt: DateTime(2026, 11, 21),
        ),
      );
      final router = await pump(
        tester,
        extra: [searchCacheProvider.overrideWithValue(cache)],
      );
      expect(find.text('Según tus búsquedas en este teléfono'), findsOneWidget);
      expect(find.text('Agotado'), findsOneWidget);
      await tester.tap(find.text('Libro pp'));
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/books/pp');
    });

    testWidgets('a failing carousel offers a retry', (tester) async {
      when(
        () => search.search(
          q: any(named: 'q'),
          filters: any(named: 'filters'),
          page: any(named: 'page'),
        ),
      ).thenThrow(const NetworkFailure());
      await pump(tester);
      expect(find.text(const NetworkFailure().message), findsOneWidget);
    });

    testWidgets('without position invites to share the location', (
      tester,
    ) async {
      await pump(tester);
      await tester.scrollUntilVisible(
        find.text('Usar mi ubicación'),
        200,
        scrollable: _page,
      );
      expect(find.textContaining('Comparte tu ubicación'), findsOneWidget);
      await tester.tap(find.text('Usar mi ubicación'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No pudimos obtener tu ubicación'), findsOne);
    });

    testWidgets('with position lists the nearest stores', (tester) async {
      final router = await pump(tester, position: (lat: 20.17, lng: -98.05));
      final container = ProviderScope.containerOf(
        tester.element(find.text('Más buscados')),
      );
      await container.read(currentPositionProvider.notifier).refresh();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Librería del Centro'),
        200,
        scrollable: _page,
      );
      expect(find.text('850 m · 10 min a pie\nLun a sáb 9:00–20:00'), findsOne);
      await tester.tap(find.text('Librería del Centro'));
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/stores/s1');
    });
  });
}
