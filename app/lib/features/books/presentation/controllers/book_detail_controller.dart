import 'package:bookia_mobile/features/books/domain/entities/book.dart';
import 'package:bookia_mobile/features/books/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel (PAT-02) of screen 07: loads one book with every store offer.
class BookDetailController extends AsyncNotifier<Book> {
  BookDetailController(this.bookId);

  final String bookId;

  @override
  Future<Book> build() => ref.watch(bookRepositoryProvider).getById(bookId);
}

final bookDetailProvider = AsyncNotifierProvider.autoDispose
    .family<BookDetailController, Book, String>(BookDetailController.new);
