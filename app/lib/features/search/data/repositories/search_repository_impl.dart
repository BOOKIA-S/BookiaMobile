import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/features/search/data/dto/book_summary_dto.dart';
import 'package:bookia_mobile/features/search/data/mappers/book_summary_mapper.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this._api);

  static const pageSize = 20;
  final ApiClient _api;

  @override
  Future<BookPage> search({String? q, String? genre, int page = 1}) async {
    final json = await _api.get<Map<String, dynamic>>(
      '/books',
      query: {'q': q, 'genre': genre, 'page': page, 'limit': pageSize},
    );
    final items = (json['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((e) => BookSummaryDto.fromJson(e).toEntity())
        .toList();
    return BookPage(
      items: items,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      page: (json['page'] as num?)?.toInt() ?? page,
    );
  }
}
