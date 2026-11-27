import 'package:bookia_mobile/core/favorites/favorite_book.dart';
import 'package:bookia_mobile/core/favorites/favorites_repository.dart';
import 'package:bookia_mobile/core/network/api_client.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<FavoriteBook>> list() async {
    final json = await _api.get<Map<String, dynamic>>('/favorites');
    return [
      for (final item in json['items'] as List? ?? const [])
        if (item case {'_id': final String id})
          FavoriteBook(
            id: id,
            title: item['title'] as String? ?? '',
            author: item['author'] as String? ?? '',
            genre: item['genre'] as String?,
            publisher: item['publisher'] as String?,
          ),
    ];
  }

  @override
  Future<Set<String>> ids() async =>
      (await list()).map((book) => book.id).toSet();

  @override
  Future<Set<String>> add(String bookId) async =>
      _bookIds(await _api.put<Map<String, dynamic>>(_path(bookId)));

  @override
  Future<Set<String>> remove(String bookId) async =>
      _bookIds(await _api.delete<Map<String, dynamic>>(_path(bookId)));

  static String _path(String bookId) =>
      '/favorites/${Uri.encodeComponent(bookId)}';

  static Set<String> _bookIds(Map<String, dynamic> json) => {
    ...(json['book_ids'] as List? ?? const []).whereType<String>(),
  };
}
