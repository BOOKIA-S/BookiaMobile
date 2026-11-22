import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/entities/recent_search.dart';

/// "Más buscados" of screen 03 (I2-11). The API has no such endpoint
/// (SPECS §5), so books are ranked from the searches saved on the phone:
/// each book scores the times its searches were made, and books near the
/// top of a result page weigh a little more than those at the bottom.
List<BookSummary> rankMostSearched(
  List<RecentSearch> searches, {
  int limit = 10,
}) {
  final score = <String, double>{};
  final latest = <String, DateTime>{};
  final books = <String, BookSummary>{};
  for (final search in searches) {
    for (final (i, book) in search.books.indexed) {
      score[book.id] = (score[book.id] ?? 0) + search.count / (i + 1);
      final seen = latest[book.id];
      if (seen == null || search.lastSearchedAt.isAfter(seen)) {
        latest[book.id] = search.lastSearchedAt;
        books[book.id] = book;
      }
    }
  }
  final ids = score.keys.toList()
    ..sort((a, b) {
      final byScore = score[b]!.compareTo(score[a]!);
      return byScore != 0 ? byScore : latest[b]!.compareTo(latest[a]!);
    });
  return [for (final id in ids.take(limit)) books[id]!];
}
