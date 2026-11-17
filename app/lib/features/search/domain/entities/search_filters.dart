/// Filters of screen 05. Null means "any"; the price range is $50–$300.
class SearchFilters {
  const SearchFilters({
    this.genre,
    this.storeId,
    this.minPrice,
    this.maxPrice,
    this.onlyAvailable = false,
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

  /// Number of active filters, for the badge of the filters button.
  int get activeCount => [
    genre != null,
    storeId != null,
    minPrice != null || maxPrice != null,
    onlyAvailable,
  ].where((active) => active).length;

  SearchFilters copyWith({bool? onlyAvailable}) => SearchFilters(
    genre: genre,
    storeId: storeId,
    minPrice: minPrice,
    maxPrice: maxPrice,
    onlyAvailable: onlyAvailable ?? this.onlyAvailable,
  );

  @override
  bool operator ==(Object other) =>
      other is SearchFilters &&
      other.genre == genre &&
      other.storeId == storeId &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.onlyAvailable == onlyAvailable;

  @override
  int get hashCode =>
      Object.hash(genre, storeId, minPrice, maxPrice, onlyAvailable);
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
