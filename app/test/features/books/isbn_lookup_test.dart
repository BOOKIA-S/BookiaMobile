import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/books/data/repositories/book_repository_impl.dart';
import 'package:bookia_mobile/features/books/domain/entities/book.dart';
import 'package:bookia_mobile/features/books/domain/repositories/book_repository.dart';
import 'package:bookia_mobile/features/books/domain/usecases/find_book_by_isbn.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_http_adapter.dart';

class _MockBookRepository extends Mock implements BookRepository {}

/// Shape of `GET /books?isbn=` (list endpoint: store has only `_id`, `name`).
const listJson = {
  'items': [
    {
      '_id': 'b1',
      'title': 'Pedro Páramo',
      'author': 'Juan Rulfo',
      'isbn': '978-607-16-1234-5',
      'offers': [
        {
          '_id': 'o1',
          'price': 120,
          'stock': 3,
          'is_available': true,
          'store': {'_id': 's1', 'name': 'Librería Centro'},
        },
      ],
      'min_price': 120,
      'total_stock': 3,
    },
  ],
  'total': 1,
  'page': 1,
  'limit': 1,
};

void main() {
  group('BookRepositoryImpl.findByIsbn', () {
    test('sends the isbn filter and maps the first book', () async {
      final adapter = FakeHttpAdapter(200, listJson);
      final book = await BookRepositoryImpl(fakeApiClient(adapter))
          .findByIsbn('9786071612345');
      expect(adapter.last?.path, '/books');
      expect(adapter.last?.queryParameters['isbn'], '9786071612345');
      expect(book?.id, 'b1');
      expect(book?.offers.single.store.name, 'Librería Centro');
    });

    test('returns null when the catalog does not have it', () async {
      final adapter = FakeHttpAdapter(200, const {
        'items': <Object>[],
        'total': 0,
      });
      final repo = BookRepositoryImpl(fakeApiClient(adapter));
      expect(await repo.findByIsbn('9780000000002'), isNull);
    });

    test('400 Invalid isbn becomes a ValidationFailure', () {
      final adapter = FakeHttpAdapter(400, const {'message': 'Invalid isbn'});
      expect(
        BookRepositoryImpl(fakeApiClient(adapter)).findByIsbn('123'),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.message,
            'message',
            'Invalid isbn',
          ),
        ),
      );
    });
  });

  group('FindBookByIsbn', () {
    late _MockBookRepository repo;
    setUp(() => repo = _MockBookRepository());

    test('strips dashes and spaces before asking the repository', () async {
      const book = Book(id: 'b1', title: 'T', author: 'A');
      when(() => repo.findByIsbn('9786071612345'))
          .thenAnswer((_) async => book);
      expect(await FindBookByIsbn(repo)(' 978-607-16-1234-5 '), book);
    });

    test('rejects an empty ISBN without calling the API', () {
      expect(
        () => FindBookByIsbn(repo)(' - '),
        throwsA(isA<ValidationFailure>()),
      );
      verifyZeroInteractions(repo);
    });
  });
}
