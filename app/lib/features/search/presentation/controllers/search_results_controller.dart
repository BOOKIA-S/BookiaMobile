import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/sort/sort_strategy.dart';
import 'package:bookia_mobile/features/search/presentation/providers.dart';
import 'package:bookia_mobile/features/search/presentation/search_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:bookia_mobile/features/search/presentation/search_query.dart';

class SearchResults {
  const SearchResults({
    required this.items,
    required this.total,
    required this.page,
    this.onlyAvailable = false,
    this.strategy = const SortByTitle(),
    this.loadingMore = false,
    this.savedAt,
  });

  /// Every row loaded so far, in API order.
  final List<BookSummary> items;
  final int total;
  final int page;
  final bool onlyAvailable;

  /// Order chosen in screen 05 or with the quick chips (PAT-09).
  final SortStrategy strategy;
  final bool loadingMore;

  /// Set when the rows come from the phone because there is no connection.
  final DateTime? savedAt;

  bool get hasMore => items.length < total;

  /// The rows to paint: sorted by [strategy], and without sold-out books
  /// when "Solo disponibles" is on.
  List<BookSummary> get visible => strategy.sort(
    onlyAvailable
        ? items.where((b) => b.availability != Availability.soldOut).toList()
        : items,
  );
}

/// ViewModel (PAT-02) of screen 04 with infinite scroll.
class SearchResultsController extends AsyncNotifier<SearchResults> {
  SearchResultsController(this.query);

  final SearchQuery query;
  SortStrategy _strategy = const SortByTitle();

  Future<SearchResults> _fetch(int page, List<BookSummary> previous) async {
    final result = await ref
        .read(searchRepositoryProvider)
        .search(q: query.q, filters: query.filters, page: page);
    if (page == 1 && !result.isOffline && ref.mounted) {
      ref.read(searchHistoryRevisionProvider.notifier).bump();
    }
    return SearchResults(
      items: [...previous, ...result.items],
      total: result.total,
      page: result.page,
      onlyAvailable: query.filters.onlyAvailable,
      strategy: _strategy,
      savedAt: result.savedAt,
    );
  }

  @override
  Future<SearchResults> build() async {
    final option = query.filters.sort;
    _strategy = sortStrategyFor(
      option,
      kmByStore: option == SortOption.distance
          ? await ref.watch(storeDistancesProvider.future)
          : const {},
    );
    return _fetch(1, const []);
  }

  /// Loads the next page; a failure keeps the rows already shown.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(
      SearchResults(
        items: current.items,
        total: current.total,
        page: current.page,
        onlyAvailable: current.onlyAvailable,
        strategy: current.strategy,
        loadingMore: true,
      ),
    );
    try {
      state = AsyncData(await _fetch(current.page + 1, current.items));
    } on Exception {
      state = AsyncData(current);
    }
  }
}

final searchResultsProvider = AsyncNotifierProvider.autoDispose
    .family<SearchResultsController, SearchResults, SearchQuery>(
      SearchResultsController.new,
    );
