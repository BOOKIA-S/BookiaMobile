import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/presentation/controllers/search_results_controller.dart';
import 'package:bookia_mobile/features/search/presentation/pages/search_results_page.dart';
import 'package:bookia_mobile/features/search/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

BookSummary book(int i, {int stock = 5}) => BookSummary(
  id: 'b$i',
  title: 'Libro $i',
  author: 'Autor',
  publisher: 'Editorial',
  minPrice: 75,
  totalStock: stock,
  storeCount: 2,
);

BookPage page(int n, {int total = 25}) => BookPage(
  items: [for (var i = 0; i < (n == 1 ? 20 : 5); i++) book((n - 1) * 20 + i)],
  total: total,
  page: n,
);

const query = (q: 'libro', genre: null);

void main() {
  late MockSearchRepository repo;
  setUp(() => repo = MockSearchRepository());

  void answer(int n, Future<BookPage> Function() result) =>
      when(() => repo.search(q: 'libro', genre: null, page: n))
          .thenAnswer((_) => result());

  test('loadMore appends the next page until total is reached', () async {
    answer(1, () async => page(1));
    answer(2, () async => page(2));
    final c = ProviderContainer(
      overrides: [searchRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    final sub = c.listen(searchResultsProvider(query), (_, _) {});
    addTearDown(sub.close);

    await c.read(searchResultsProvider(query).future);
    await c.read(searchResultsProvider(query).notifier).loadMore();
    final r = c.read(searchResultsProvider(query)).requireValue;
    expect(r.items.length, 25);
    expect(r.hasMore, isFalse);

    await c.read(searchResultsProvider(query).notifier).loadMore();
    verifyNever(() => repo.search(q: 'libro', genre: null, page: 3));
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [searchRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: SearchResultsPage(query: query)),
    ),
  );

  testWidgets('shows count, price and availability badges', (tester) async {
    answer(
      1,
      () async =>
          BookPage(items: [book(1), book(2, stock: 2)], total: 2, page: 1),
    );
    await pump(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('2 libros encontrados'), findsOneWidget);
    expect(find.text(r'desde $75.00'), findsNWidgets(2));
    expect(find.text('En 2 librerías · 5 piezas'), findsOneWidget);
    expect(find.text('Últimas 2 · 2 librerías'), findsOneWidget);
  });

  testWidgets('empty results invite to scan the ISBN', (tester) async {
    answer(1, () async => const BookPage(items: [], total: 0, page: 1));
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('escanear el ISBN'), findsOneWidget);
  });

  testWidgets('an error shows its message and retries', (tester) async {
    answer(1, () => Future.error(const NetworkFailure()));
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text(const NetworkFailure().message), findsOneWidget);

    answer(1, () async => page(1));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('25 libros encontrados'), findsOneWidget);
  });
}
