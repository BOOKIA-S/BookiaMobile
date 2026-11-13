import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/features/search/data/repositories/search_repository_impl.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

Map<String, Object?> bookJson(String id, {int stock = 5, num? price = 75}) => {
  '_id': id,
  'title': 'Pedro Páramo',
  'author': 'Juan Rulfo',
  'publisher': 'RM',
  'min_price': price,
  'total_stock': stock,
  'offers': [
    {'_id': 'o1', 'stock': stock, 'is_available': stock > 0},
    {'_id': 'o2', 'stock': 0, 'is_available': false},
  ],
};

void main() {
  test('maps GET /books into a BookPage of BookSummary', () async {
    final api = _MockApiClient();
    when(
      () => api.get<Map<String, dynamic>>('/books', query: any(named: 'query')),
    ).thenAnswer(
      (_) async => {
        'items': [bookJson('b1')],
        'total': 21,
        'page': 2,
        'limit': 20,
      },
    );

    final page = await SearchRepositoryImpl(api).search(q: 'rulfo', page: 2);

    final book = page.items.single;
    expect(book.id, 'b1');
    expect(book.minPrice, 75.0);
    expect(book.storeCount, 1);
    expect(page.total, 21);
    expect(page.page, 2);
    final query = verify(
      () => api.get<Map<String, dynamic>>(
        '/books',
        query: captureAny(named: 'query'),
      ),
    ).captured.single;
    expect(query, {'q': 'rulfo', 'genre': null, 'page': 2, 'limit': 20});
  });

  test('availability is green, amber (≤ 2) or grey (sold out)', () {
    BookSummary of(int stock) => BookSummary(
      id: 'x',
      title: '',
      author: '',
      publisher: '',
      minPrice: null,
      totalStock: stock,
      storeCount: 1,
    );
    expect(of(3).availability, Availability.available);
    expect(of(2).availability, Availability.low);
    expect(of(0).availability, Availability.soldOut);
  });
}
