import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/features/books/data/repositories/book_repository_impl.dart';
import 'package:bookia_mobile/features/books/domain/repositories/book_repository.dart';
import 'package:bookia_mobile/features/books/domain/usecases/find_book_by_isbn.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider/DI (PAT-03): screens depend on the interface, not on data/.
final bookRepositoryProvider = Provider<BookRepository>(
  (ref) => BookRepositoryImpl(ref.watch(apiClientProvider)),
);

/// Used by the ISBN scanner (screen 06, S03).
final findBookByIsbnProvider = Provider<FindBookByIsbn>(
  (ref) => FindBookByIsbn(ref.watch(bookRepositoryProvider)),
);
