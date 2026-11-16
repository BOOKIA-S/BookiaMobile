import 'package:bookia_mobile/features/search/data/dto/book_summary_dto.dart';
import 'package:bookia_mobile/features/search/data/mappers/book_summary_mapper.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/domain/sort/sort_strategy.dart';
import 'package:bookia_mobile/features/search/presentation/search_query.dart';
import 'package:flutter_test/flutter_test.dart';

BookSummary _book(
  String title, {
  double? price,
  List<String> stores = const [],
}) => BookSummary(
  id: title,
  title: title,
  author: '',
  publisher: '',
  minPrice: price,
  totalStock: price == null ? 0 : 3,
  storeCount: stores.length,
  storeIds: stores,
);

List<String> _titles(List<BookSummary> books) => [
  for (final b in books) b.title,
];

/// Unit tests of the Strategy pattern (PAT-09, PRU-01).
void main() {
  final books = [
    _book('rayuela', price: 180, stores: ['far']),
    _book('Aura', price: 95, stores: ['near', 'far']),
    _book('Pedro Páramo', stores: ['near']),
    _book('El llano', price: 95, stores: ['unknown']),
  ];

  test('SortByTitle orders A to Z ignoring case', () {
    expect(_titles(const SortByTitle().sort(books)), [
      'Aura',
      'El llano',
      'Pedro Páramo',
      'rayuela',
    ]);
  });

  test(
    'SortByPrice puts the cheapest first, ties in API order, sold out last',
    () {
      expect(_titles(const SortByPrice().sort(books)), [
        'Aura',
        'El llano',
        'rayuela',
        'Pedro Páramo',
      ]);
    },
  );

  test('SortByDistance uses the nearest store with stock; unknown last', () {
    const strategy = SortByDistance({'near': 0.8, 'far': 4.2});
    expect(strategy.distanceOf(books[1]), 0.8);
    expect(strategy.distanceOf(books[3]), isNull);
    expect(_titles(strategy.sort(books)), [
      'Aura',
      'Pedro Páramo',
      'rayuela',
      'El llano',
    ]);
  });

  test('sorting returns a new list and leaves the input untouched', () {
    final sorted = const SortByTitle().sort(books);
    expect(identical(sorted, books), isFalse);
    expect(books.first.title, 'rayuela');
  });

  test('sortStrategyFor builds the strategy of each option', () {
    expect(sortStrategyFor(SortOption.title), isA<SortByTitle>());
    expect(sortStrategyFor(SortOption.price), isA<SortByPrice>());
    final d = sortStrategyFor(SortOption.distance, kmByStore: {'s': 1});
    expect((d as SortByDistance).kmByStore, {'s': 1});
  });

  test('the DTO keeps the ids of the stores that have stock', () {
    final book = BookSummaryDto.fromJson({
      '_id': 'b1',
      'offers': [
        {
          'is_available': true,
          'store': {'_id': 's1', 'name': 'Centro'},
        },
        {
          'is_available': false,
          'store': {'_id': 's2', 'name': 'Norte'},
        },
        {'is_available': true, 'store': null},
      ],
    }).toEntity();
    expect(book.storeIds, ['s1']);
    expect(book.storeCount, 2);
  });

  test('the order travels in the route as sort=', () {
    const query = (q: null, filters: SearchFilters(sort: SortOption.distance));
    expect(searchQueryParams(query), {'sort': 'distance'});
    expect(searchQueryFrom({'sort': 'distance'}), query);
    expect(searchQueryFrom({'sort': 'nope'}).filters.sort, SortOption.title);
    expect(searchQueryParams((q: 'x', filters: const SearchFilters())), {
      'q': 'x',
    });
  });
}
