import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/books/data/dto/book_dto.dart';
import 'package:bookia_mobile/features/books/data/mappers/book_mapper.dart';
import 'package:bookia_mobile/features/books/data/repositories/book_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

/// Shape of `GET /books/:id` (API_CONTRACT.md).
const detailJson = {
  '_id': 'b1',
  'title': 'Pedro Páramo',
  'author': 'Juan Rulfo',
  'genre': 'Novela',
  'publisher': 'RM',
  'edition': '',
  'isbn': '978-607-16-1234-5',
  'total_stock': 7,
  'offers': [
    {
      '_id': 'o1',
      'price': 120,
      'stock': 5,
      'is_available': true,
      'store': {'_id': 's1', 'name': 'Librería Centro', 'address': 'Av. 5'},
    },
    {
      '_id': 'o2',
      'price': 95.5,
      'stock': 2,
      'is_available': true,
      'store': {'_id': 's2', 'name': 'Papelería Sol', 'address': ' '},
    },
    {
      '_id': 'o3',
      'price': 80,
      'stock': 0,
      'is_available': false,
      'store': {'_id': 's3', 'name': 'El Rincón'},
    },
  ],
};

void main() {
  test('BookDto.fromJson reads snake_case fields and every offer', () {
    final dto = BookDto.fromJson(detailJson);
    expect(dto.id, 'b1');
    expect(dto.isbn, '978-607-16-1234-5');
    expect(dto.offers, hasLength(3));
    expect(dto.offers[1].price, 95.5);
    expect(dto.offers[1].store.name, 'Papelería Sol');
  });

  test('mapper orders offers, sums stock and skips sold-out prices', () {
    final book = BookDto.fromJson(detailJson).toEntity();
    expect(book.edition, isNull);
    expect(book.offers[1].store.address, isNull);
    expect(book.totalStock, 7);
    expect(book.isAvailable, isTrue);
    expect(book.minPrice, 95.5);
    expect(book.offersByPrice.map((o) => o.id), ['o2', 'o1', 'o3']);
    expect(book.offers[1].isLow, isTrue);
    expect(book.offers[2].isAvailable, isFalse);
  });

  test('a book without offers is sold out with no price', () {
    final book = BookDto.fromJson(const {
      '_id': 'b2',
      'title': 'Sin ofertas',
      'author': 'Anónimo',
    }).toEntity();
    expect(book.offers, isEmpty);
    expect(book.isAvailable, isFalse);
    expect(book.minPrice, isNull);
  });

  test('getById calls GET /books/:id and maps the book', () async {
    final adapter = FakeHttpAdapter(200, detailJson);
    final book = await BookRepositoryImpl(fakeApiClient(adapter)).getById('b1');
    expect(adapter.last?.path, '/books/b1');
    expect(book.title, 'Pedro Páramo');
    expect(book.offers.first.store.name, 'Librería Centro');
  });

  test('getById throws NotFoundFailure on 404', () {
    final adapter = FakeHttpAdapter(404, const {'message': 'Book not found'});
    expect(
      BookRepositoryImpl(fakeApiClient(adapter)).getById('nope'),
      throwsA(isA<NotFoundFailure>()),
    );
  });
}
