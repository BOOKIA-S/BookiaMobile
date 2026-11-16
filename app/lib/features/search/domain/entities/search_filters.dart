import 'package:bookia_mobile/features/search/domain/sort/sort_strategy.dart';

/// Filters of screen 05. Null means "any"; the price range is $50–$300.
class SearchFilters {
  const SearchFilters({
    this.genre,
    this.storeId,
    this.minPrice,
    this.maxPrice,
    this.onlyAvailable = false,
    this.sort = SortOption.title,
  });

  static const priceFloor = 50.0;
  static const priceCeiling = 300.0;

  final String? genre;

  /// `store_id` of the chosen store.
  final String? storeId;
  final double? minPrice;
  final double? maxPrice;

  /// Hides sold-out books. `GET /books` has no such parameter, so it is
  /// applied to the rows already loaded.
  final bool onlyAvailable;

  /// Order of the rows; applied on the device, `GET /books` sorts by title.
  final SortOption sort;

  /// Number of active filters, for the badge of the filters button.
  int get activeCount => [
    genre != null,
    storeId != null,
    minPrice != null || maxPrice != null,
    onlyAvailable,
  ].where((active) => active).length;

  SearchFilters copyWith({bool? onlyAvailable, SortOption? sort}) =>
      SearchFilters(
        genre: genre,
        storeId: storeId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        onlyAvailable: onlyAvailable ?? this.onlyAvailable,
        sort: sort ?? this.sort,
      );

  @override
  bool operator ==(Object other) =>
      other is SearchFilters &&
      other.genre == genre &&
      other.storeId == storeId &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.onlyAvailable == onlyAvailable &&
      other.sort == sort;

  @override
  int get hashCode =>
      Object.hash(genre, storeId, minPrice, maxPrice, onlyAvailable, sort);
}

/// A store of the "Establecimiento" filter.
class StoreOption {
  const StoreOption({required this.id, required this.name});

  final String id;
  final String name;
}

/// What the filters sheet can offer, from `/books/filters` and `/stores`.
class FilterOptions {
  const FilterOptions({required this.genres, required this.stores});

  final List<String> genres;
  final List<StoreOption> stores;
}
