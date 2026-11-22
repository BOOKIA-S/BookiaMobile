/// Repository (PAT-01) of the reader's favorite books. Throws a Failure.
abstract interface class FavoritesRepository {
  /// `GET /favorites`: ids of the saved books.
  Future<Set<String>> ids();

  /// `PUT /favorites/:bookId` -> the ids after saving it (idempotent).
  Future<Set<String>> add(String bookId);

  /// `DELETE /favorites/:bookId` -> the ids after removing it.
  Future<Set<String>> remove(String bookId);
}
