/// Data the home screen (03) needs. Implemented in data/ (PAT-01).
abstract interface class HomeRepository {
  /// Genre names from `GET /books/filters`. Throws a Failure on error.
  Future<List<String>> getGenres();
}
