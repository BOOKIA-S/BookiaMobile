import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef SearchQuery = ({String? q, String? genre});

class SearchResults {
  const SearchResults({
    required this.items,
    required this.total,
    required this.page,
    this.loadingMore = false,
  });

  final List<BookSummary> items;
  final int total;
  final int page;
  final bool loadingMore;

  bool get hasMore => items.length < total;
}

/// ViewModel (PAT-02) of screen 04 with infinite scroll.
class SearchResultsController extends AsyncNotifier<SearchResults> {
  SearchResultsController(this.query);

  final SearchQuery query;

  Future<SearchResults> _fetch(int page, List<BookSummary> previous) async {
    final result = await ref
        .read(searchRepositoryProvider)
        .search(q: query.q, genre: query.genre, page: page);
    return SearchResults(
      items: [...previous, ...result.items],
      total: result.total,
      page: result.page,
    );
  }

  @override
  Future<SearchResults> build() => _fetch(1, const []);

  /// Loads the next page; a failure keeps the rows already shown.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(
      SearchResults(
        items: current.items,
        total: current.total,
        page: current.page,
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
