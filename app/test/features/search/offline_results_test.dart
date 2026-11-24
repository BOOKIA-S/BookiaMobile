import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/features/search/data/datasources/local/search_cache_data_source.dart';
import 'package:bookia_mobile/features/search/data/models/cached_search_model.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/presentation/pages/search_results_page.dart';
import 'package:bookia_mobile/features/search/presentation/providers.dart';
import 'package:bookia_mobile/features/search/presentation/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

const _book = BookSummary(
  id: 'b1',
  title: 'Pedro Páramo',
  author: 'Juan Rulfo',
  publisher: 'RM',
  minPrice: 89,
  totalStock: 4,
  storeCount: 2,
);

void main() {
  test('savedAtLabel uses day/month and 24 h time', () {
    expect(savedAtLabel(DateTime(2026, 11, 21, 8, 5)), '21/11 08:05');
  });

  testWidgets('screen 04 marks rows saved on the phone', (tester) async {
    final repo = MockSearchRepository();
    when(() => repo.search(q: 'rulfo', filters: const SearchFilters(), page: 1))
        .thenAnswer(
          (_) async => BookPage(
            items: const [_book],
            total: 1,
            page: 1,
            savedAt: DateTime(2026, 11, 21, 18, 5),
          ),
        );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [searchRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: SearchResultsPage(
            query: (q: 'rulfo', filters: SearchFilters()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Sin conexión. Resultados guardados el 21/11 18:05'),
      findsOneWidget,
    );
    expect(find.text('1 libro encontrado'), findsOneWidget);
    expect(find.text('Pedro Páramo'), findsOneWidget);
  });

  testWidgets('screen 03 lists recent searches and reopens them', (
    tester,
  ) async {
    final cache = MemorySearchCacheDataSource();
    await cache.write(
      CachedSearchModel.fromPage(
        q: null,
        filters: const SearchFilters(genre: 'Poesía', storeId: 's1'),
        page: const BookPage(items: [_book], total: 1, page: 1),
        savedAt: DateTime(2026, 11, 21),
      ),
    );
    final router = createRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...offlineOverrides(),
          searchCacheProvider.overrideWithValue(cache),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Búsquedas recientes'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'Poesía'));
    await tester.pumpAndSettle();
    expect(
      router.state.uri.toString(),
      '/search?genre=Poes%C3%ADa&store_id=s1',
    );
  });
}
