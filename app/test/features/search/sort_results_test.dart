import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/domain/sort/sort_strategy.dart';
import 'package:bookia_mobile/features/search/presentation/controllers/search_results_controller.dart';
import 'package:bookia_mobile/features/search/presentation/providers.dart';
import 'package:bookia_mobile/features/search/presentation/widgets/filters_sheet.dart';
import 'package:bookia_mobile/features/search/presentation/widgets/quick_chips.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/domain/repositories/store_repository.dart';
import 'package:bookia_mobile/features/stores/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class _MockStoreRepository extends Mock implements StoreRepository {}

BookSummary _book(String title, double price, String store) => BookSummary(
  id: title,
  title: title,
  author: '',
  publisher: '',
  minPrice: price,
  totalStock: 3,
  storeCount: 1,
  storeIds: [store],
);

final _page = BookPage(
  items: [_book('Aura', 150, 'far'), _book('Rayuela', 90, 'near')],
  total: 2,
  page: 1,
);

/// ViewModel and widget tests of the order of screen 04 (PRU-01, PRU-02).
void main() {
  late MockSearchRepository search;
  late _MockStoreRepository stores;

  setUp(() {
    search = MockSearchRepository();
    stores = _MockStoreRepository();
    registerFallbackValue(const SearchFilters());
    when(
      () => search.search(
        q: any(named: 'q'),
        filters: any(named: 'filters'),
        page: any(named: 'page'),
      ),
    ).thenAnswer((_) async => _page);
    when(() => stores.getStores(lat: 20.17, lng: -98.05)).thenAnswer(
      (_) async => const [
        Store(id: 'near', name: 'A', address: '', distanceKm: 0.4),
        Store(id: 'far', name: 'B', address: '', distanceKm: 3.1),
      ],
    );
  });

  Future<List<String>> visible(
    SortOption sort, {
    ({double lat, double lng})? position,
  }) async {
    final c = ProviderContainer(
      overrides: [
        searchRepositoryProvider.overrideWithValue(search),
        storeRepositoryProvider.overrideWithValue(stores),
        userPositionProvider.overrideWithValue(position),
      ],
    );
    addTearDown(c.dispose);
    final query = (q: null, filters: SearchFilters(sort: sort));
    final sub = c.listen(searchResultsProvider(query), (_, _) {});
    addTearDown(sub.close);
    final r = await c.read(searchResultsProvider(query).future);
    return [for (final b in r.visible) b.title];
  }

  test('the controller applies the strategy chosen in the route', () async {
    expect(await visible(SortOption.title), ['Aura', 'Rayuela']);
    expect(await visible(SortOption.price), ['Rayuela', 'Aura']);
  });

  test('distance uses /stores/near with the position of the user', () async {
    expect(
      await visible(SortOption.distance, position: (lat: 20.17, lng: -98.05)),
      ['Rayuela', 'Aura'],
    );
    verify(() => stores.getStores(lat: 20.17, lng: -98.05)).called(1);
  });

  test(
    'without position distance keeps the API order and skips /stores',
    () async {
      expect(await visible(SortOption.distance), ['Aura', 'Rayuela']);
      verifyNever(
        () => stores.getStores(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      );
    },
  );

  Widget app(Widget child, {bool located = false}) => ProviderScope(
    overrides: [
      searchRepositoryProvider.overrideWithValue(search),
      userPositionProvider.overrideWithValue(
        located ? (lat: 20.17, lng: -98.05) : null,
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );

  testWidgets('quick chips toggle the order; Más cerca needs location', (
    tester,
  ) async {
    SearchFilters? changed;
    await tester.pumpWidget(
      app(
        QuickChips(
          filters: const SearchFilters(sort: SortOption.price),
          onChanged: (f) => changed = f,
        ),
      ),
    );
    final cerca = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Más cerca'),
    );
    expect(cerca.onSelected, isNull);

    await tester.tap(find.text('Más barato'));
    expect(changed!.sort, SortOption.title);
    await tester.tap(find.text('Disponible'));
    expect(changed!.onlyAvailable, isTrue);
    expect(changed!.sort, SortOption.price);
  });

  testWidgets('the sheet returns the order chosen in Ordenar por', (
    tester,
  ) async {
    when(search.getFilterOptions)
        .thenAnswer((_) async => const FilterOptions(genres: [], stores: []));
    when(
      () => search.count(
        q: any(named: 'q'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => 2);
    SearchFilters? result;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showFiltersSheet(context, (
              q: null,
              filters: const SearchFilters(),
            )),
            child: const Text('abrir'),
          ),
        ),
        located: true,
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(
      find.text('Activa tu ubicación para ordenar por distancia.'),
      findsNothing,
    );

    await tester.tap(find.text('Distancia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver 2 resultados'));
    await tester.pumpAndSettle();
    expect(result!.sort, SortOption.distance);
  });
}
