import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/books/domain/entities/book.dart';
import 'package:bookia_mobile/features/books/domain/repositories/book_repository.dart';

/// Finds a book by the ISBN read from a barcode or typed by the reader.
/// Returns null when no bookstore in the catalog has it.
class FindBookByIsbn {
  const FindBookByIsbn(this._books);

  final BookRepository _books;

  Future<Book?> call(String isbn) {
    final digits = isbn.replaceAll(RegExp(r'[\s-]'), '');
    if (digits.isEmpty) {
      throw const ValidationFailure('Escribe o escanea un ISBN.');
    }
    return _books.findByIsbn(digits);
  }
}
