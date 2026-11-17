import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';

/// What screen 04 shows: the text typed in 03 and the filters of 05.
typedef SearchQuery = ({String? q, SearchFilters filters});

/// Reads `/search?q=&genre=&store_id=&min_price=&max_price=&available=`.
SearchQuery searchQueryFrom(Map<String, String> params) => (
  q: params['q'],
  filters: SearchFilters(
    genre: params['genre'],
    storeId: params['store_id'],
    minPrice: double.tryParse(params['min_price'] ?? ''),
    maxPrice: double.tryParse(params['max_price'] ?? ''),
    onlyAvailable: params['available'] == 'true',
  ),
);

/// The inverse of [searchQueryFrom], so filters survive back navigation.
Map<String, String> searchQueryParams(SearchQuery query) {
  final f = query.filters;
  return {
    if (query.q != null) 'q': query.q!,
    if (f.genre != null) 'genre': f.genre!,
    if (f.storeId != null) 'store_id': f.storeId!,
    if (f.minPrice != null) 'min_price': '${f.minPrice!.round()}',
    if (f.maxPrice != null) 'max_price': '${f.maxPrice!.round()}',
    if (f.onlyAvailable) 'available': 'true',
  };
}
