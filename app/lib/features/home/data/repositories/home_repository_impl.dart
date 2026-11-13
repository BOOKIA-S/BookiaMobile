import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/features/home/data/dto/book_filters_dto.dart';
import 'package:bookia_mobile/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<String>> getGenres() async {
    final json = await _api.get<Map<String, dynamic>>('/books/filters');
    return BookFiltersDto.fromJson(json).genres;
  }
}
