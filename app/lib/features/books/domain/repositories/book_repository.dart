import 'package:bookia_mobile/features/books/domain/entities/book.dart';

/// Repository (PAT-01). Every method throws a Failure on error.
abstract interface class BookRepository {
  /// `GET /books/:id`: the book with every store offer.
  Future<Book> getById(String id);
}
