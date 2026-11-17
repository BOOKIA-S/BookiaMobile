import 'package:bookia_mobile/features/home/data/dto/book_filters_dto.dart';
import 'package:bookia_mobile/features/search/data/dto/store_option_dto.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';

/// Adapter (PAT-07): `/books/filters` and `/stores` bodies to [FilterOptions].
FilterOptions toFilterOptions(
  BookFiltersDto filters,
  List<StoreOptionDto> stores,
) => FilterOptions(
  genres: filters.genres,
  stores: [for (final s in stores) StoreOption(id: s.id, name: s.name)],
);
