import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/search/data/dto/book_summary_dto.dart';
import 'package:bookia_mobile/features/search/data/mappers/book_summary_mapper.dart';
import 'package:bookia_mobile/features/search/data/repositories/search_repository_impl.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

/// Data tests of search (PRU-01) through the real ApiClient, without network.
void main() {
  SearchRepositoryImpl repoWith(FakeHttpAdapter adapter) =>
      SearchRepositoryImpl(fakeApiClient(adapter));

  test('sends genre, page and limit to GET /books and skips nulls', () async {
    final adapter = FakeHttpAdapter(200, {
      'items': <Object>[],
      'total': 0,
      'page': 3,
      'limit': 20,
    });

    await repoWith(adapter)
        .search(filters: const SearchFilters(genre: 'Novela'), page: 3);

    expect(adapter.last!.path, '/books');
    expect(adapter.last!.queryParameters, {
      'genre': 'Novela',
      'page': 3,
      'limit': 20,
    });
  });

  test('a body without total or page falls back to the request', () async {
    final adapter = FakeHttpAdapter(200, {
      'items': [
        {'_id': 'b1', 'title': 'Aura'},
        'not a book',
      ],
    });

    final page = await repoWith(adapter).search(q: 'aura', page: 2);

    expect(page.items.single.title, 'Aura');
    expect(page.total, 1);
    expect(page.page, 2);
  });

  test('HTTP errors arrive as Failure, never as DioException', () async {
    expect(
      repoWith(FakeHttpAdapter(500, {'message': 'boom'})).search(q: 'x'),
      throwsA(isA<ServerFailure>()),
    );
    expect(
      repoWith(FakeHttpAdapter(400, {'message': 'Invalid page'})).search(),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('an unexpected body shape is a ServerFailure', () {
    expect(
      repoWith(FakeHttpAdapter(200, ['not', 'a', 'page'])).search(),
      throwsA(isA<ServerFailure>()),
    );
  });

  group('BookSummaryDto (PAT-05) and mapper (PAT-07)', () {
    test('missing fields get safe defaults and sold out has no price', () {
      final book = BookSummaryDto.fromJson({'_id': 'b9'}).toEntity();
      expect(book.title, '');
      expect(book.author, '');
      expect(book.publisher, '');
      expect(book.minPrice, isNull);
      expect(book.totalStock, 0);
      expect(book.storeCount, 0);
    });

    test('counts only stores whose offer is available', () {
      final book = BookSummaryDto.fromJson({
        '_id': 'b1',
        'min_price': 120,
        'total_stock': 7,
        'offers': [
          {'_id': 'o1', 'is_available': true},
          {'_id': 'o2', 'is_available': true},
          {'_id': 'o3', 'is_available': false},
          'bad offer',
        ],
      }).toEntity();
      expect(book.minPrice, 120.0);
      expect(book.totalStock, 7);
      expect(book.storeCount, 2);
    });
  });
}
