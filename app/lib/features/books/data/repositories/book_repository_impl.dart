import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/features/books/data/dto/book_dto.dart';
import 'package:bookia_mobile/features/books/data/mappers/book_mapper.dart';
import 'package:bookia_mobile/features/books/domain/entities/book.dart';
import 'package:bookia_mobile/features/books/domain/repositories/book_repository.dart';

class BookRepositoryImpl implements BookRepository {
  const BookRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<Book> getById(String id) async {
    final json = await _api.get<Map<String, dynamic>>(
      '/books/${Uri.encodeComponent(id)}',
    );
    return BookDto.fromJson(json).toEntity();
  }
}
