import 'dart:async';

import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/presentation/controllers/search_results_controller.dart';
import 'package:bookia_mobile/features/search/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

BookSummary _book(int i) => BookSummary(
  id: 'b$i',
  title: 'Libro $i',
  author: 'Autor',
  publisher: 'Editorial',
  minPrice: 90,
  totalStock: 3,
  storeCount: 1,
);

BookPage _page(int n, int size, {int total = 30}) => BookPage(
  items: [for (var i = 0; i < size; i++) _book((n - 1) * 20 + i)],
  total: total,
  page: n,
);

const _query = (q: null, genre: 'Poesía');

/// ViewModel tests of screen 04 (PRU-01).
void main() {
  late MockSearchRepository repo;
  late ProviderContainer c;

  setUp(() {
    repo = MockSearchRepository();
    // No automatic retry, so a Failure surfaces at once as AsyncError.
    c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [searchRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
  });

  void answer(int n, Future<BookPage> Function() result) =>
      when(() => repo.search(q: null, genre: 'Poesía', page: n))
          .thenAnswer((_) => result());

  /// Keeps the auto-dispose provider alive; call it after the answers.
  void listen() {
    final sub = c.listen(searchResultsProvider(_query), (_, _) {});
    addTearDown(sub.close);
  }

  SearchResultsController notifier() =>
      c.read(searchResultsProvider(_query).notifier);
  SearchResults value() => c.read(searchResultsProvider(_query)).requireValue;

  test('build loads page 1 with the query of the route', () async {
    answer(1, () async => _page(1, 20));

    listen();
    final r = await c.read(searchResultsProvider(_query).future);

    expect(r.items.length, 20);
    expect(r.page, 1);
    expect(r.hasMore, isTrue);
    expect(r.loadingMore, isFalse);
  });

  test('a failure on page 1 becomes AsyncError with the Failure', () async {
    answer(1, () => Future.error(const NetworkFailure()));

    listen();
    await expectLater(
      c.read(searchResultsProvider(_query).future),
      throwsA(isA<NetworkFailure>()),
    );
    expect(c.read(searchResultsProvider(_query)).error, isA<NetworkFailure>());
  });

  test('a failed loadMore keeps the rows already shown', () async {
    answer(1, () async => _page(1, 20));
    answer(2, () => Future.error(const ServerFailure()));
    listen();
    await c.read(searchResultsProvider(_query).future);

    await notifier().loadMore();

    expect(value().items.length, 20);
    expect(value().page, 1);
    expect(value().loadingMore, isFalse);
  });

  test('loadMore marks loadingMore and ignores calls meanwhile', () async {
    final pending = Completer<BookPage>();
    answer(1, () async => _page(1, 20));
    answer(2, () => pending.future);
    listen();
    await c.read(searchResultsProvider(_query).future);

    final first = notifier().loadMore();
    expect(value().loadingMore, isTrue);
    await notifier().loadMore();
    pending.complete(_page(2, 10));
    await first;

    verify(() => repo.search(q: null, genre: 'Poesía', page: 2)).called(1);
    expect(value().items.length, 30);
    expect(value().hasMore, isFalse);
  });

  test('loadMore does nothing while page 1 is loading', () async {
    final pending = Completer<BookPage>();
    answer(1, () => pending.future);

    listen();
    await notifier().loadMore();
    pending.complete(_page(1, 5, total: 5));
    await c.read(searchResultsProvider(_query).future);

    verifyNever(() => repo.search(q: null, genre: 'Poesía', page: 2));
  });
}
