import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/presentation/pages/search_results_page.dart';
import 'package:bookia_mobile/features/search/presentation/providers.dart';
import 'package:bookia_mobile/features/search/presentation/widgets/filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

/// Widget test of screen 05 (PRU-02).
void main() {
  testWidgets('the sheet shows options, counts and returns the filters', (
    tester,
  ) async {
    final repo = MockSearchRepository();
    registerFallbackValue(const SearchFilters());
    when(repo.getFilterOptions).thenAnswer(
      (_) async => const FilterOptions(
        genres: ['Novela', 'Poesía'],
        stores: [StoreOption(id: 's1', name: 'Librería Centro')],
      ),
    );
    when(
      () => repo.count(
        q: 'luna',
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (i) async =>
          (i.namedArguments[#filters] as SearchFilters).genre == null ? 9 : 3,
    );
    SearchFilters? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [searchRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showFiltersSheet(context, (
                q: 'luna',
                filters: const SearchFilters(),
              )),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Librería Centro'), findsNothing);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Ver 9 resultados'), findsOneWidget);

    await tester.tap(find.text('Poesía'));
    await tester.pumpAndSettle();
    expect(find.text('Ver 3 resultados'), findsOneWidget);

    await tester.tap(find.text('Limpiar'));
    await tester.pumpAndSettle();
    expect(find.text('Ver 9 resultados'), findsOneWidget);

    await tester.tap(find.text('Novela'));
    await tester.tap(find.text('Solo disponibles'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver 3 resultados'));
    await tester.pumpAndSettle();
    expect(result, const SearchFilters(genre: 'Novela', onlyAvailable: true));
  });

  testWidgets('results hide sold-out rows and badge the active filters', (
    tester,
  ) async {
    BookSummary book(String title, int stock) => BookSummary(
      id: title,
      title: title,
      author: 'Autor',
      publisher: 'Editorial',
      minPrice: stock > 0 ? 75 : null,
      totalStock: stock,
      storeCount: stock > 0 ? 1 : 0,
    );
    const filters = SearchFilters(genre: 'Novela', onlyAvailable: true);
    final repo = MockSearchRepository();
    when(() => repo.search(q: null, filters: filters, page: 1)).thenAnswer(
      (_) async => BookPage(
        items: [book('Aura', 4), book('Rayuela', 0)],
        total: 21,
        page: 1,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [searchRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: SearchResultsPage(query: (q: null, filters: filters)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('21 libros encontrados · solo disponibles'),
      findsOneWidget,
    );
    expect(find.text('Aura'), findsOneWidget);
    expect(find.text('Rayuela'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Cargar más'), findsOneWidget);
  });
}
