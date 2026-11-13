import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';

abstract interface class SearchRepository {
  /// Throws a Failure on error.
  Future<BookPage> search({String? q, String? genre, int page = 1});
}
