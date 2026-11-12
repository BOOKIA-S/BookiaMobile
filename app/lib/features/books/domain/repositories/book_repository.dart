import 'package:bookia_mobile/features/books/domain/entities/book.dart';

/// Repository (PAT-01). Every method throws a Failure on error.
abstract interface class BookRepository {
  /// `GET /books/:id`: the book with every store offer.
  Future<Book> getById(String id);

  /// `GET /books?isbn=`: exact lookup of a scanned or typed ISBN.
  /// Null when the catalog does not have it; ValidationFailure when the API
  /// rejects the ISBN (`Invalid isbn`).
  Future<Book?> findByIsbn(String isbn);
}
