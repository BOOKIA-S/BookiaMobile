import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';

/// Orders of the results list (screen 04), chosen in screen 05.
enum SortOption { title, price, distance }

/// Strategy (PAT-09): each order is a class, so the list never needs a
/// chain of `if`s. Sorting returns a new list and keeps ties in API order.
abstract interface class SortStrategy {
  List<BookSummary> sort(List<BookSummary> books);
}

/// A to Z, ignoring case.
class SortByTitle implements SortStrategy {
  const SortByTitle();

  @override
  List<BookSummary> sort(List<BookSummary> books) => _stable(
    books,
    (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
  );
}

/// Cheapest "desde $X" first; sold-out books (no price) go last.
class SortByPrice implements SortStrategy {
  const SortByPrice();

  @override
  List<BookSummary> sort(List<BookSummary> books) =>
      _stable(books, (a, b) => _nullsLast(a.minPrice, b.minPrice));
}

/// Nearest store with stock first. [kmByStore] comes from `/stores/near`;
/// books in no known store go last.
class SortByDistance implements SortStrategy {
  const SortByDistance(this.kmByStore);

  final Map<String, double> kmByStore;

  /// Distance to the nearest store that has the book, or null.
  double? distanceOf(BookSummary book) {
    final km = [
      for (final id in book.storeIds)
        if (kmByStore[id] case final double d) d,
    ];
    return km.isEmpty ? null : km.reduce((a, b) => a < b ? a : b);
  }

  @override
  List<BookSummary> sort(List<BookSummary> books) =>
      _stable(books, (a, b) => _nullsLast(distanceOf(a), distanceOf(b)));
}

/// Factory of the strategy for [option]. Distance needs [kmByStore].
SortStrategy sortStrategyFor(
  SortOption option, {
  Map<String, double> kmByStore = const {},
}) => switch (option) {
  SortOption.title => const SortByTitle(),
  SortOption.price => const SortByPrice(),
  SortOption.distance => SortByDistance(kmByStore),
};

int _nullsLast(double? a, double? b) => a == null
    ? (b == null ? 0 : 1)
    : b == null
    ? -1
    : a.compareTo(b);

/// `List.sort` is not stable, so ties fall back to the original position.
List<BookSummary> _stable(
  List<BookSummary> books,
  int Function(BookSummary a, BookSummary b) compare,
) {
  final indexed = [for (var i = 0; i < books.length; i++) (i, books[i])];
  indexed.sort((x, y) {
    final c = compare(x.$2, y.$2);
    return c != 0 ? c : x.$1.compareTo(y.$1);
  });
  return [for (final (_, book) in indexed) book];
}
