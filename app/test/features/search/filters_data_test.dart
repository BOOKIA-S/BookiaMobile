import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/features/search/data/repositories/search_repository_impl.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/presentation/controllers/search_results_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_http_adapter.dart';

class _MockApiClient extends Mock implements ApiClient {}

BookSummary _book(String id, int stock) => BookSummary(
  id: id,
  title: id,
  author: '',
  publisher: '',
  minPrice: stock > 0 ? 80 : null,
  totalStock: stock,
  storeCount: stock > 0 ? 1 : 0,
);

void main() {
  const filters = SearchFilters(
    genre: 'Novela',
    storeId: 's1',
    minPrice: 80,
    maxPrice: 200,
    onlyAvailable: true,
  );

  test(
    'filters go to GET /books as store_id, min_price and max_price',
    () async {
      final adapter = FakeHttpAdapter(200, {'items': <Object>[], 'total': 4});
      final repo = SearchRepositoryImpl(fakeApiClient(adapter));

      await repo.search(q: 'luna', filters: filters);
      expect(adapter.last!.queryParameters, {
        'q': 'luna',
        'genre': 'Novela',
        'store_id': 's1',
        'min_price': 80,
        'max_price': 200,
        'page': 1,
        'limit': 20,
      });

      expect(await repo.count(filters: filters), 4);
      expect(adapter.last!.queryParameters['limit'], 1);
    },
  );

  test('filter options join /books/filters genres and /stores', () async {
    final api = _MockApiClient();
    when(() => api.get<Map<String, dynamic>>('/books/filters')).thenAnswer(
      (_) async => {
        'genres': ['Novela'],
        'publishers': ['RM'],
      },
    );
    when(() => api.get<List<dynamic>>('/stores')).thenAnswer(
      (_) async => [
        {'_id': 's1', 'name': 'Librería Centro', 'address': 'Centro'},
      ],
    );

    final o = await SearchRepositoryImpl(api).getFilterOptions();

    expect(o.genres, ['Novela']);
    expect(o.stores.single.id, 's1');
    expect(o.stores.single.name, 'Librería Centro');
  });

  test('route params round-trip and count active filters', () {
    const query = (q: 'luna', filters: filters);
    final params = searchQueryParams(query);
    expect(params, {
      'q': 'luna',
      'genre': 'Novela',
      'store_id': 's1',
      'min_price': '80',
      'max_price': '200',
      'available': 'true',
    });
    expect(searchQueryFrom(params), query);
    expect(filters.activeCount, 4);
    expect(const SearchFilters().activeCount, 0);
  });

  test('"Solo disponibles" hides sold-out rows but keeps paging', () {
    final r = SearchResults(
      items: [_book('a', 3), _book('b', 0)],
      total: 30,
      page: 1,
      onlyAvailable: true,
    );
    expect(r.visible.map((b) => b.id), ['a']);
    expect(r.hasMore, isTrue);
  });
}
