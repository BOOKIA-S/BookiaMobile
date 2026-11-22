import 'package:bookia_mobile/features/home/domain/usecases/rank_most_searched.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Books of the "Más buscados" carousel and where they come from.
class MostSearched {
  const MostSearched({required this.books, required this.fromHistory});

  final List<BookSummary> books;

  /// True when ranked from the searches of this phone; false when there is
  /// no history yet and the first books of the catalog are shown instead.
  final bool fromHistory;
}

/// ViewModel (PAT-02) of the "Más buscados" carousel (I2-11).
class MostSearchedController extends AsyncNotifier<MostSearched> {
  static const size = 10;

  @override
  Future<MostSearched> build() async {
    ref.watch(searchHistoryRevisionProvider);
    final history = await ref
        .watch(searchHistoryRepositoryProvider)
        .recent(limit: 20);
    final ranked = rankMostSearched(history, limit: size);
    if (ranked.isNotEmpty) {
      return MostSearched(books: ranked, fromHistory: true);
    }
    final page = await ref.read(searchRepositoryProvider).search();
    return MostSearched(
      books: page.items.take(size).toList(),
      fromHistory: false,
    );
  }
}

final mostSearchedProvider =
    AsyncNotifierProvider.autoDispose<MostSearchedController, MostSearched>(
      MostSearchedController.new,
    );
